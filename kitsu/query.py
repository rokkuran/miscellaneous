import numpy as np
import pandas as pd

from datetime import datetime

import pymongo
from pymongo import MongoClient

from sklearn.preprocessing import MultiLabelBinarizer, Imputer


def print_cursor(cursor, n):
    for i, x in enumerate(cursor):
        if i < n:
            print x
        else:
            print ''
            break
    print ''


if __name__ == '__main__':
    client = MongoClient()
    db = client.kitsu

    # query by top level field in document
    # cursor = db.anime.find({'averageRating': {'$gt': 4.2}})
    cursor = db.anime.find()
    # print_cursor(cursor, 1)

    attributes = ['slug', 'averageRating', 'ageRating', 'ageRatingGuide',
                  'episodeCount', 'startDate', 'endDate', 'showType', 'genres']
    results = []
    for i, x in enumerate(cursor):
        print i, x['slug'], x['averageRating']
        results.append([x[k] for k in attributes])

    df = pd.DataFrame(results, columns=attributes)
    # print df.head()

    def apply_mlb(df, col):
        mlb = MultiLabelBinarizer()
        x = mlb.fit_transform(df[col])
        labels = ['{}_{}'.format(col, v) for v in mlb.classes_]
        x = pd.DataFrame(x, columns=labels)
        del df[col]
        df = pd.concat([df, x], axis=1)
        return df

    df = apply_mlb(df, 'genres')

    df['ageRatingGuide'] = df.ageRatingGuide.apply(lambda s: s.replace(' ', '').split(','))
    df = apply_mlb(df, 'ageRatingGuide')

    # fmt = '%Y-%m-%d'
    # df['endDate'] = df.endDate.apply(lambda s: datetime.strptime(s, fmt))
    # df['startDate'] = df.startDate.apply(lambda s: datetime.strptime(s, fmt))
    # print df.head()
