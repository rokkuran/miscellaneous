import socket
import re
import csv
import random
import numpy as np

from time import sleep
from datetime import datetime


HOST = 'irc.twitch.tv'
PORT = 6667
# NICK = 'eponymouse'
# PASS = 'oauth:bqrru03xz1g5l9ehh6w17zwmuyijzg'  # eponymouse

NICK = 'MarkovEchoBot'
PASS = 'oauth:l7er3yslp8mthfrwqkrox1livcshyy'  # MarkovEchoBot

# CHAT_MSG = re.compile(r"^:\w+!\w+@\w+\.tmi\.twitch\.tv PRIVMSG #\w+ :")
time_format = '%Y-%m-%d %H:%M:%S'


class Markov(object):
    # def __init__(self, text):
    def __init__(self, words):
        self.cache = {}
        # self.words = text.split()
        self.words = words
        self.word_size = len(self.words)
        self.database()

    def triples(self):
        if len(self.words) < 3:
            return

        for i in range(len(self.words) - 2):
            yield (self.words[i], self.words[i+1], self.words[i+2])

    def database(self):
        for w1, w2, w3 in self.triples():
            key = (w1, w2)
            if key in self.cache:
                self.cache[key].append(w3)
            else:
                self.cache[key] = [w3]

    def generate_markov_text(self, size=25):
        seed = random.randint(0, self.word_size - 3)
        seed_word, next_word = self.words[seed], self.words[seed + 1]
        w1, w2 = seed_word, next_word
        gen_words = []
        for i in xrange(size):
            gen_words.append(w1)
            # choose from the list of possible next states in accordance with
            # the frequencies at which they occur
            w1, w2 = w2, random.choice(self.cache[(w1, w2)])
        gen_words.append(w2)
        return ' '.join(gen_words)

    def generate_markov_text_close(self, size=25, past_size=100):
        seed = random.randint(0, self.word_size - 3)
        seed_word = self.words[-past_size:][seed]
        next_word = self.words[-past_size:][seed + 1]
        w1, w2 = seed_word, next_word
        gen_words = []
        for i in xrange(size):
            gen_words.append(w1)
            w1, w2 = w2, random.choice(self.cache[(w1, w2)])
        gen_words.append(w2)
        return ' '.join(gen_words)


class Spammer(object):
    """"""
    def __init__(self, username, channel, n_words=10000, markov_max_length=6,
                 history_path=None, output_path=None):
        super(Spammer, self).__init__()
        self.username = username
        self.channel = channel
        self.n_words = n_words
        self.markov_max_length = markov_max_length
        self.output_path = output_path

        self.connect(username, channel)
        print username, channel, '\n', '-' * (len(username + channel) + 1)

    def connect(self, username, channel):
        self._socket = socket.socket()
        self._socket.connect((HOST, PORT))
        self._socket.send("PASS {}\r\n".format(PASS).encode("utf-8"))
        self._socket.send("NICK {}\r\n".format(username).encode("utf-8"))
        self._socket.send("JOIN {}\r\n".format(channel).encode("utf-8"))

    def chat(self, msg):
        self._socket.send("PRIVMSG {} :{}\r\n".format(self.channel, msg))

    def _write_bot_msg(self, msg):
        args = (self.output_path, self.channel, self.username)
        filepath = '%s/%s_%s.csv' % args
        with open(filepath, 'ab') as f:
            writer = csv.writer(f)
            t = datetime.strftime(datetime.now(), time_format)
            writer.writerow([t, NICK, msg])

    def _update_words(self, words, msg):
        if len(words) < self.n_words:
            words.extend(msg.split())
        else:
            for word in msg.split():
                words.pop(0)
                words.append(word)
        return words

    def generate_spam(self, words):
        spammer = Markov(words)
        spam_length = np.random.randint(1, self.markov_max_length)
        spam = spammer.generate_markov_text(spam_length)
        print '\n\n%s\n%s\n%s\n\n' % ('*' * 75, spam, '*' * 75)
        return spam

    def action_msg(self, words):
        spam = self.generate_spam(words)
        # self.chat(spam)
        self._msg_count = 0  # reset message count

        if self.output_path is not None:
            self._write_bot_msg(spam)

    # def process_msg(self, words, min_words_len=100):
    #     try:
    #         if (self._msg_count % 50 == 0) & (len(words) >= min_words_len):
    #             self.action_msg(words)
    #     except UnicodeEncodeError as e:
    #         print '\n\n%s\n\n' % e
    #     except UnicodeDecodeError as e:
    #         print '\n\n%s\n\n' % e
    #     except AttributeError as e:
    #         print '\n\n%s\n\n' % e
    #     except KeyError as e:
    #         print '\n\n%s\n\n' % e

    def _ping_pong(self, response):
        if response == "PING :tmi.twitch.tv\r\n":
            # send pong back to prevent timeout
            self._socket.send("PONG :tmi.twitch.tv\r\n".encode("utf-8"))
            return True
        else:
            return False

    def _get_response(self):
        response = self._socket.recv(1024).decode("utf-8")
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
        print '%s: %s' % (username, message)
        return username, message

    def spam(self):
        words = []
        self._msg_count = 0
        n_msg_per_sec = 30  # number of messages per second
        while True:
            response = self._get_response()
            if response:
                username, msg = self._process_msg(response)
                words = self._update_words(words, msg)
                self._msg_count += 1

                # self.process_msg(words)
                # try:
                if (self._msg_count % 50 == 0) & (len(words) >= 100):
                    self.action_msg(words)

                # except UnicodeEncodeError as e:
                #     print '\n\n%s\n\n' % e
                # except UnicodeDecodeError as e:
                #     print '\n\n%s\n\n' % e
                # except AttributeError as e:
                #     print '\n\n%s\n\n' % e
                # except KeyError as e:
                #     print '\n\n%s\n\n' % e

            sleep(1 / float(n_msg_per_sec))


path = '/home/rokkuran/workspace/miscellaneous/twitch/'
# markov_echo_bot = Spammer(NICK, "#wagamamatv", markov_max_length=10)
# markov_echo_bot.spam()

# markov_echo_bot = AdmiralSpammer(NICK, "#admiralbulldog")
# markov_echo_bot.spam(10000, 5)

# markov_echo_bot = Spammer(NICK, "#shroud", path)
# markov_echo_bot.spam(15000, 5)

markov_echo_bot = Spammer(NICK, "#sing_sing", markov_max_length=6)
markov_echo_bot.spam()
