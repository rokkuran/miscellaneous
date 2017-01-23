import numpy as np
import pandas as pd
import nltk
import yaml
import re

import pymongo
from pymongo import MongoClient


class Markov(object):
    def __init__(self, words, use_pos=False):
        self.cache = {}
        self.words = words
        self.word_size = len(self.words)
        self.use_pos = use_pos
        self.database()

    def trigrams(self):
        if len(self.words) < 3:
            return

        for i in xrange(len(self.words) - 2):
            words = self.words[i:i + 3]
            if self.use_pos:
                yield tuple(nltk.pos_tag(words))
            else:
                yield tuple(words)

    def database(self):
        for w1, w2, w3 in self.trigrams():
            key = (w1, w2)
            if key in self.cache:
                self.cache[key].append(w3)
            else:
                self.cache[key] = [w3]

    def _get_words(self):
        seed = np.random.randint(0, self.word_size - 3)
        words = [self.words[seed], self.words[seed + 1]]
        if self.use_pos:
            return tuple(nltk.pos_tag(words))
        else:
            return words

    def _get_next_words(self, w1, w2):
        if self.use_pos:
            if (w1, w2) in self.cache:
                i = np.random.randint(0, len(self.cache[(w1, w2)]))
                return w2, self.cache[(w1, w2)][i]
            else:
                # w1 = (word, pos_tag)
                for key in self.cache:
                    k1, k2 = key
                    if (w1[0] == k1[0]) & (w2[0] == k2[0]):
                        i = np.random.randint(0, len(self.cache[key]))
                        return w2, self.cache[key][i]
        else:
            return w2, np.random.choice(self.cache[(w1, w2)])

    # def _punctuation_fix(self, text):
    #     return re.sub(r'\s([?.!"](?:\s|$))', r'\1', text)
    #
    # def _space_after_emote_fix(self, text):
    #     path = '/home/rokkuran/workspace/miscellaneous/twitch/'
    #     emotes = yaml.load(open(path + 'emotes.yml', 'rb'))['emotes_official']
    #     a = [s for s in emotes if s in text]
    #     for emote in a:
    #         text = text.replace('%s.' % emote, '%s ' % emote)
    #     return text

    def _text_post_processing(self, text):
        return text

    def generate_text(self, size=25):
        w1, w2 = self._get_words()
        gen_words = []
        for _ in xrange(size - 1):
            # print w1, w2
            gen_words.append(w1)
            w1, w2 = self._get_next_words(w1, w2)
        gen_words.append(w2)
        return self._text_post_processing(gen_words)

    def generate_text_proper_end(self, size=25):
        w1, w2 = self._get_words()
        gen_words = []

        for _ in xrange(size - 1):
            # print w1, w2
            gen_words.append(w1)
            w1, w2 = self._get_next_words(w1, w2)

        if w2[0] not in '.?':
            while w2[0] not in '.?':
                # print w1, w2
                gen_words.append(w1)
                w1, w2 = self._get_next_words(w1, w2)
        gen_words.append(w2)
        return self._text_post_processing(gen_words)


class MarkovTwitch(Markov):
    def _punctuation_fix(self, text):
        return re.sub(r'\s([?.!"](?:\s|$))', r'\1', text)

    def _space_after_emote_fix(self, text):
        path = '/home/rokkuran/workspace/miscellaneous/twitch/'
        emotes = yaml.load(open(path + 'emotes.yml', 'rb'))['emotes_official']
        a = [s for s in emotes if s in text]
        for emote in a:
            text = text.replace('%s.' % emote, '%s ' % emote)
        return text

    def _text_post_processing(self, gen_words):
        if self.use_pos:
            text = ' '.join(np.array(gen_words)[:, 0].tolist())
        else:
            text = ' '.join(gen_words)
        text = self._punctuation_fix(text)
        text = self._space_after_emote_fix(text)
        return text


def test_twitch():
    path = '/home/rokkuran/workspace/miscellaneous/twitch/'
    # filename = '#admiralbulldog.csv'
    filename = '#wagamamatv.csv'
    cols = ['timestamp', 'username', 'comment']
    df = pd.read_csv(path + filename, header=0, names=cols)

    a = df.comment.values[-15000:]
    x = np.array(a)

    # emotes = yaml.load(open(path + 'emotes.yml', 'rb'))['emotes_official']
    # x = []
    # for s in a:
    #     stripped = ' '.join([q for q in s.split() if q not in emotes])
    #     if stripped:
    #         x.append(stripped)
    # x = np.array(x)

    for i, s in enumerate(x):
        if s[-1] not in '.?':
            x[i] += '.'

    words = nltk.word_tokenize(' '.join(x))

    hmm = MarkovTwitch(words, use_pos=True)
    return hmm


def get_data(cursor):
    attributes = ['slug', 'synopsis']
    results = []
    for i, x in enumerate(cursor):
        print i, x['slug'], x['averageRating']
        results.append([x[k] for k in attributes])

    df = pd.DataFrame(results, columns=attributes)
    return df


def test_anime_synopsis():
    client = MongoClient()
    db = client.kitsu
    cursor = db.anime.find()

    df = get_data(cursor)
    # words = ' '.join([s for s in df.synopsis.values[-10000:]]).split()
    words = ' '.join([s for s in df.synopsis.values]).split()

    hmm = Markov(words, use_pos=True)
    return hmm


# hmm = test_twitch()
hmm = test_anime_synopsis()
# print hmm.generate_text(10)
print hmm.generate_text_proper_end(10)
