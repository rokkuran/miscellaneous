import socket
import re
import csv

from time import sleep
from datetime import datetime


HOST = "irc.twitch.tv"
PORT = 6667
NICK = "eponymouse"
PASS = "oauth:bqrru03xz1g5l9ehh6w17zwmuyijzg"

RATE = 30  # messages per second
CHAT_MSG = re.compile(r"^:\w+!\w+@\w+\.tmi\.twitch\.tv PRIVMSG #\w+ :")
time_format = '%Y-%m-%d %H:%M:%S'


class Harvester(object):
    """"""
    def __init__(self, username, channel):
        super(Harvester, self).__init__()
        self.username = username
        self.channel = channel
        print username, channel, '\n', '-' * (len(username + channel) + 1)

        self._socket = socket.socket()
        self._socket.connect((HOST, PORT))
        self._socket.send("PASS {}\r\n".format(PASS).encode("utf-8"))
        self._socket.send("NICK {}\r\n".format(self.username).encode("utf-8"))
        self._socket.send("JOIN {}\r\n".format(self.channel).encode("utf-8"))

    def collect(self):
        while True:
            response = self._socket.recv(1024).decode("utf-8")
            if response == "PING :tmi.twitch.tv\r\n":
                # send pong back to prevent timeout
                self._socket.send("PONG :tmi.twitch.tv\r\n".encode("utf-8"))
            else:
                username = re.search(r"\w+", response).group(0)
                message = CHAT_MSG.sub("", response).strip('\r\n')

                if 'tmi.twitch.tv' not in message:
                    print '%s: %s' % (username, message)
                    try:
                        with open('{}.csv'.format(self.channel), 'ab') as f:
                            writer = csv.writer(f)
                            t = datetime.strftime(datetime.now(), time_format)
                            writer.writerow([t, username, message])
                    except UnicodeEncodeError as e:
                        print '\n\n%s\n\n' % e
                    except UnicodeEncodeError as e:
                        print '\n\n%s\n\n' % e
                    except AttributeError as e:
                        print '\n\n%s\n\n' % e

            sleep(1 / float(RATE))


CHAN = "#wagamamatv"
# CHAN = "#pyrionflax"
# CHAN = "#sing_sing"
# CHAN = '#lirik'
# CHAN = '#purgegamers'
# CHAN = '#ppd'
# CHAN = '#admiralbulldog'

streamer = Harvester(NICK, CHAN)
streamer.collect()
