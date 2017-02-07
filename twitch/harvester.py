from bot import Bot

import yaml
import csv
import sys

from datetime import datetime


try:
    CHAN = sys.argv[1]
except Exception as e:
    raise e

config = yaml.safe_load(open('config.yml', 'rb'))
HOST = config['HOST']
PORT = config['PORT']
NICK = config['NICK']
PASS = config['PASS']


class Harvester(Bot):
    """"""
    def __init__(self, output_path, verbose=True, **kwargs):
        super(Harvester, self).__init__(**kwargs)
        self.output_path = output_path
        self.verbose = verbose

    def action(self, username, msg):
        if self.verbose:
            print '%s: %s' % (username, msg)

        with open('{}/{}.csv'.format(self.output_path, self.channel), 'ab') as f:
            writer = csv.writer(f)
            t = datetime.strftime(datetime.now(), '%Y-%m-%d %H:%M:%S')
            writer.writerow([t, username, msg])


if __name__ == '__main__':
    path = '/home/rokkuran/workspace/miscellaneous/twitch/output/'
    harvester = Harvester(username=NICK, channel=CHAN, output_path=path)
    harvester.run()
