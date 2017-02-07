import socket
import re
import yaml

from time import sleep
from collections import Counter

from nltk import word_tokenize
from nltk.corpus import stopwords
from string import punctuation


config = yaml.safe_load(open('config.yml', 'rb'))
HOST = config['HOST']
PORT = config['PORT']
NICK = config['NICK']
PASS = config['PASS']


class Bot(object):
    """"""
    def __init__(self, username, channel, n_msg_per_sec=100):
        super(Bot, self).__init__()
        self.username = username
        self.channel = channel
        self.connect(username, channel)
        print username, channel, '\n', '-' * (len(username + channel) + 1)

        self._msg_count = 0
        self.n_msg_per_sec = n_msg_per_sec

    def connect(self, username, channel):
        self._socket = socket.socket()
        self._socket.connect((HOST, PORT))
        self._socket.send("PASS {}\r\n".format(PASS).encode("utf-8"))
        self._socket.send("NICK {}\r\n".format(username).encode("utf-8"))
        self._socket.send("JOIN {}\r\n".format(channel).encode("utf-8"))

    def chat(self, msg):
        self._socket.send("PRIVMSG {} :{}\r\n".format(self.channel, msg))

    def _ping_pong(self, response):
        if response == "PING :tmi.twitch.tv\r\n":
            # send pong back to prevent timeout
            self._socket.send("PONG :tmi.twitch.tv\r\n".encode("utf-8"))
            return True
        else:
            return False

    def _get_response(self):
        try:
            response = self._socket.recv(1024).decode("utf-8")
        except UnicodeDecodeError as e:
            print '\n\n%s\n\n' % e
            return False

        if self._ping_pong(response):
            return False
        elif ':tmi.twitch.tv' in response:
            return False
        else:
            return response

    def _process_msg(self, response):
        username = re.search(r"\w+", response).group(0)
        mask = re.compile(r"^:\w+!\w+@\w+\.tmi\.twitch\.tv PRIVMSG #\w+ :")
        message = mask.sub("", response).strip('\r\n')
        return username, message

    def action(self, msg):
        return NotImplementedError()

    def run(self):
        while True:
            response = self._get_response()
            if response:
                username, msg = self._process_msg(response)
                self.action(msg)

            sleep(1 / float(self.n_msg_per_sec))


class CountBot(Bot):
    """"""
    def __init__(self, output_path=None, **kwargs):
        super(CountBot, self).__init__(**kwargs)
        self.output_path = output_path
        self.counts = Counter()
        self.recent = []

    def _update_counts(self, msg):
        tokens = word_tokenize(msg)
        exclusions = stopwords.words('english') + list(punctuation)
        tokens = [x for x in tokens if x not in exclusions]
        self.counts.update(tokens)

        if len(self.recent) >= 200:
            self.recent = self.recent[200:] + tokens
        else:
            self.recent.extend(tokens)

        if self._msg_count % 100 == 0:
            n_top = 10
            recent_counts = Counter(self.recent).most_common(n_top)

            print '\nToken Counts @ msg_count=%s; n_keys=%s; n_counts=%s' \
                % (self._msg_count, len(self.counts), sum(self.counts.values()))

            for x, y in zip(self.counts.most_common(n_top), recent_counts):
                print '%s | %s' % (x, y)

    def action(self, msg):
        self._msg_count += 1
        self._update_counts(msg)


if __name__ == '__main__':
    bot = CountBot(username=NICK, channel="#beyondthesummit2")
    bot.run()
