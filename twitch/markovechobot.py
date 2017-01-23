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

RATE = 30  # messages per second
CHAT_MSG = re.compile(r"^:\w+!\w+@\w+\.tmi\.twitch\.tv PRIVMSG #\w+ :")
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
    def __init__(self, username, channel, output_path=None):
        super(Spammer, self).__init__()
        self.username = username
        self.channel = channel
        print username, channel, '\n', '-' * (len(username + channel) + 1)

        self.output_path = output_path

        self._socket = socket.socket()
        self._socket.connect((HOST, PORT))
        self._socket.send("PASS {}\r\n".format(PASS).encode("utf-8"))
        self._socket.send("NICK {}\r\n".format(self.username).encode("utf-8"))
        self._socket.send("JOIN {}\r\n".format(self.channel).encode("utf-8"))

    def chat(self, msg):
        self._socket.send("PRIVMSG {} :{}\r\n".format(self.channel, msg))

    def _write_bot_msg(self, msg):
        args = (self.output_path, self.channel, self.username)
        filepath = '%s/%s_%s.csv' % args
        with open(filepath, 'ab') as f:
            writer = csv.writer(f)
            t = datetime.strftime(datetime.now(), time_format)
            writer.writerow([t, NICK, msg])

    def spam(self, n_words=100, max_len=6):
        words = []
        i = 0
        while True:
            response = self._socket.recv(1024).decode("utf-8")
            if response == "PING :tmi.twitch.tv\r\n":
                # send pong back to prevent timeout
                self._socket.send("PONG :tmi.twitch.tv\r\n".encode("utf-8"))
            else:
                username = re.search(r"\w+", response).group(0)
                if 'bot' not in username:
                    message = CHAT_MSG.sub("", response).strip('\r\n')
                    if len(words) < n_words:
                        words.extend(message.split())
                        i += 1
                    else:
                        for word in message.split():
                            words.pop(0)
                            words.append(word)
                        i += 1

                    if 'tmi.twitch.tv' not in message:
                        print '%s: %s' % (username, message)
                        try:
                            # if (i % 50 == 0) & (len(words) >= n_words):
                            # if (i % 50 == 0) & (len(words) >= 200):
                            if (i % 50 == 0):
                                spammer = Markov(words)
                                spam_length = np.random.randint(1, max_len)
                                spam = spammer.generate_markov_text(spam_length)
                                # spam = spammer.generate_markov_text_close(size=spam_length)
                                a = '*' * (len(spam) + 1)
                                print '\n\n%s\n%s\n%s\n\n' % (a, spam, a)
                                # self.chat(spam)
                                i = 0

                                if self.output_path is not None:
                                    self._write_bot_msg(spam)

                        except UnicodeEncodeError as e:
                            print '\n\n%s\n\n' % e
                        except UnicodeDecodeError as e:
                            print '\n\n%s\n\n' % e
                        except AttributeError as e:
                            print '\n\n%s\n\n' % e
                        except KeyError as e:
                            print '\n\n%s\n\n' % e

            sleep(1 / float(RATE))


# markov_echo_bot = Spammer(NICK, "#wagamamatv")
# markov_echo_bot.spam(10000, 30)

# markov_echo_bot = AdmiralSpammer(NICK, "#admiralbulldog")
# markov_echo_bot.spam(10000, 5)

path = '/home/rokkuran/workspace/miscellaneous/twitch/'
markov_echo_bot = Spammer(NICK, "#shroud", path)
markov_echo_bot.spam(15000, 5)
