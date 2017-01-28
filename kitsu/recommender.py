import numpy as np
import pandas as pd
from collections import Counter

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
    anime = {}
    users = {}
    usernames = {}
    for i, item in enumerate(cursor):
        users[i] = item['user_id']
        usernames[item['name']] = i
        # print i, item['name']
        for entry in item['library']:
            anime_id, rating = entry['anime_id'], entry['rating']
            j = anime_id_distinct.index(anime_id)
            if j not in anime:
                anime[j] = entry['title']
            train[i, j] = rating

    print 'matrix size: %s\n' % str(train.shape)

    user_similarity = pairwise_distances(train, metric='cosine')
    item_similarity = pairwise_distances(train.T, metric='cosine')

    # n = 0
    # q = np.argsort(user_similarity[n])[1:]
    # a, b = train[n], train[q[0]]
    # r = [i for i, (x, y) in enumerate(zip(a, b)) if (x == 0) & (y == 5)]

    def recommendations(train, similarity_matrix, index, n_recs, n_users,
                        min_rating):
        q = similar_users(similarity_matrix[index], n_users)
        a = train[index]

        items = []
        for b in train[q]:
            g = enumerate(zip(a, b))
            r = [i for i, (x, y) in g if (x == 0) & (y >= min_rating)]
            items.extend(r)

        # TODO: weight results by rating and count
        rf = Counter(items).most_common(n_recs)
        return rf

    def similar_users(similarity_vector, n):
        # exclude first result, which will always be the original user vector
        return np.argsort(similarity_vector)[1:n + 1]

    # user_id = 4016
    # user_id = 0
    # user_index = [k for k, v in users.items() if v == user_id][0]
    # name = 'vikhyat'
    # name = 'Josh'
    name = 'muon'
    user_index = usernames[name]
    print 'recommendations: %s | user_index=%s' % (name, user_index)
    rf = recommendations(train=train, similarity_matrix=user_similarity,
                         index=user_index, n_recs=5, n_users=5, min_rating=2.5)
    # print rf

    for i, (anime_index, count) in enumerate(rf, start=1):
        title = anime[anime_index].encode('utf-8')
        print '%s: count=%s; %s' % (i, count, title)

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
