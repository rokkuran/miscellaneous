import numpy as np
import pandas as pd

import seaborn as sns

import pymongo
from pymongo import MongoClient

from sklearn.metrics.pairwise import pairwise_distances


sns.set(style="white", color_codes=True)


if __name__ == '__main__':
    client = MongoClient()
    db = client.kitsu

    n_users = db.users.count()
    anime_id_distinct = db.users.distinct("library.anime_id")
    n_anime = len(anime_id_distinct)
    train = np.zeros((n_users, n_anime))

    cursor = db.users.find()
    for i, item in enumerate(cursor):
        for anime in item['library']:
            anime_id, rating = anime['anime_id'], anime['rating']
            j = anime_id_distinct.index(anime_id)
            train[i, j] = rating

    print train.shape

    user_similarity = pairwise_distances(train, metric='cosine')

    n = 0
    q = np.argsort(user_similarity[n])
    q = q[[x for x in xrange(len(q)) if x != n]]
    print q[:5]

    item_similarity = pairwise_distances(train.T, metric='cosine')

    # df = pd.DataFrame(user_similarity)
    # def plot_dist(data, i, j, kind='scatter'):
    #     x, y = data[i], data[j]
    #     g = sns.jointplot(x, y, kind=kind)
    #     plt.show()

    # user_similarity = pairwise_distances(train, metric='cosine')
    # item_similarity = pairwise_distances(train.T, metric='cosine')

    # sparsity = round(1.0 - n_users / float(n_users * n_anime), 3)
    # print 'sparsity = %.4f' % sparsity
    #
    # import scipy.sparse as sp
    # from scipy.sparse.linalg import svds
    #
    # # get SVD components from train matrix. Choose k.
    # u, s, vt = svds(train, k=20)
    # s_diag_matrix = np.diag(s)
    # X_pred = np.dot(np.dot(u, s_diag_matrix), vt)
    # print X_pred
    # # print 'User-based CF MSE: ' + str(rmse(X_pred, test_data_matrix))
