from pso import Particle, pso

import numpy as np
import pandas as pd

from sklearn import datasets
from sklearn import metrics
from sklearn.preprocessing import LabelEncoder, StandardScaler, LabelBinarizer
from sklearn.model_selection import ShuffleSplit, StratifiedShuffleSplit
from sklearn.pipeline import Pipeline, FeatureUnion
from sklearn.decomposition import PCA
from sklearn.svm import LinearSVC, SVC
from sklearn.linear_model import LogisticRegression


def cv_split_generator(X, y, splitter):
    """
    Train and validation set split generator.
    """
    g = enumerate(splitter.split(X, y))
    for i, (train_idx, val_idx) in g:
        X_train, X_val = X[train_idx], X[val_idx]
        y_train, y_val = y[train_idx], y[val_idx]
        yield i, X_train, X_val, y_train, y_val


def pso_parameter_tuning(clf, X, y, bounds, swarm_size, n_iter, n_splits=5):
    """
    Particle swarm optimisation based parameter tuning.
    """
    def minimise(*x):
        """"""
        params = {k: x[i] for i, (k, _) in enumerate(bounds)}
        clf.set_params(**params)

        pipeline = Pipeline([
            ('pca', Pipeline([
                ('scaler', StandardScaler()),
                ('pca', PCA(n_components=3)),
            ])),
            ('clf', clf)
        ])

        # TODO: need same splits but different randoms in pso
        # maybe generalises better without?
        ss = StratifiedShuffleSplit(n_splits=n_splits, test_size=0.2)  #, random_state=77)
        cv_splits = cv_split_generator(X=X, y=y, splitter=ss)

        ll = []
        for i, X_train, X_val, y_train, y_val in cv_splits:
            model = pipeline.fit(X_train, y_train)
            y_pred = model.predict(X_val)
            # TODO: use better loss metric for minimisation
            # ll.append(metrics.log_loss(y_val, y_pred))
            ll.append(1 - metrics.accuracy_score(y_val, y_pred))

        return np.mean(ll)

    g = pso(minimise, swarm_size, bounds, n_iter=10, omega=0.75, phi_p=0.02,
            phi_g=0.1, verbose=False)
    return g


if __name__ == '__main__':
    iris = datasets.load_iris()
    X = iris.data
    y = iris.target
    labels = iris.target_names

    # np.random.seed(77)
    clf = LogisticRegression(solver='lbfgs')
    swarm_size = 50
    n_iter = 10
    bounds = [
        ('C', [0.001, 10000]),
        ('tol', [1e-5, 1e-3])]
    pso_parameter_tuning(clf, X, y, bounds, swarm_size, n_iter)
