import numpy as np
import matplotlib.pyplot as plt


class Particle(object):
    """"""
    def __init__(self, x, v):
        super(Particle, self).__init__()
        self.x = x  # position
        self.p = x  # best known position
        self.v = v  # velocity


def pso(f, swarm_size, b, n_iter=10, omega=1, phi_p=1, phi_g=1):
    b_low, b_high = b
    x = np.random.uniform(b_low, b_high, [swarm_size])
    p = x
    v = np.random.uniform(-abs(b_high - b_low), abs(b_high - b_low), [swarm_size])

    particles = [Particle(x[i], v[i]) for i in xrange(swarm_size)]

    for i, particle in enumerate(particles):
        if i == 0:
            g = particle.p
        elif f(particle.p) < f(g):
            g = particle.p

    i = 0
    while i < n_iter:
        for j, particle in enumerate(particles):
            # update particle's velocity
            r_p, r_g = np.random.uniform(0, 1, 2)
            particle.v = omega * particle.v
            particle.v += phi_p * r_p * (particle.p - particle.x)
            particle.v += phi_g * r_g * (g - particle.x)

            # update particle's position
            particle.x += particle.v

            if f(particle.x) < f(particle.p):
                print '  %d: %d particle best position updated | %.4f -> %.4f [f = %.4f]' % (i, j, particle.p, particle.x, f(particle.p))
                particle.p = particle.x

                if f(particle.p) < f(g):
                    print '  %d: %d new global best | %.4f -> %.4f [f = %.4f]' % (i, j, g, particle.p, f(particle.p))
                    g = particle.p
        i += 1
    return g


if __name__ == '__main__':
    np.random.seed(77)
    swarm_size = 100
    n_iter = 50
    b = [0, 1]

    def f(x):
        a = 0.8  # location of minimum
        return -np.exp(-(x - a)**2)

    def rosenbrock(x, y):
        # The rosenbrock function: min @ (1, 1 )
        return (1 - x)**2 + 100 * (y - x**2)**2

    z = pso(f, swarm_size, b, n_iter=n_iter)
    print '\nglobal best after %d iterations = %.4f' % (n_iter, z)

    xs = np.linspace(b[0], b[1], 100)
    plt.plot(xs, f(xs), '-')
    plt.show()
