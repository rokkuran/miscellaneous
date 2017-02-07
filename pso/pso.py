import numpy as np


class Particle(object):
    """
    Particle object with position, best position and velocity properties.
    """
    def __init__(self, x, v):
        super(Particle, self).__init__()
        self.x = x  # position
        self.p = x.copy()  # best known position
        self.v = v  # velocity
        self.f_x = 0  # last function value for x
        self.f_p = 0  # last function value for p


def pso(f, swarm_size, bounds, n_iter=10, omega=0.75, phi_p=0.02, phi_g=0.1,
        verbose=False):
    """
    Particle swarm optimisation for n-dimensional spaces within bounds given.

    f: function to minimise.
    swarm_size: number of particles in swarm.
    bounds: position constraints on search space of form:
        [('name', [b_low, b_high])]
        e.g. [('x', [-1, 2]), ('y', [-2, 3])]
    n_iter: number of iterations.
    omega: previous velocity component update rate
    phi_p: particle contribution to velocity update
    phi_g: global contributio to velocity update

    """
    ps = 'running particle swarm optimisation...\n\n'
    args = (swarm_size, n_iter, omega)
    ps += 'swarm_size = %d\nn_iter = %d\nomega = %s\n' % args
    ps += 'phi_p = %s\nphi_g = %s\n' % (phi_p, phi_g)
    print ps

    n_dim = len(bounds)

    x, v = [], []  # TODO: initialise with numpy arrays
    for i, (_, b) in enumerate(bounds):
        b_low, b_high = b
        x.append(np.random.uniform(b_low, b_high, swarm_size))
        abs_b_diff = abs(b_high - b_low)
        v.append(np.random.uniform(-abs_b_diff, abs_b_diff, swarm_size))
    x, v = np.array(x), np.array(v)

    particles = [Particle(x[:, i], v[:, i]) for i in xrange(swarm_size)]

    for i, particle in enumerate(particles):
        if i == 0:
            g = particle.p.copy()
        elif f(*particle.p) < f(*g):
            g = particle.p.copy()

    f_g = f(*g)

    i = 0
    while i < n_iter:
        for j, particle in enumerate(particles):
            # update particle's velocity
            r_p, r_g = np.random.uniform(0, 1, [2, n_dim])
            particle.v = omega * particle.v
            particle.v += phi_p * r_p * (particle.p - particle.x)
            particle.v += phi_g * r_g * (g - particle.x)

            # update particle's position
            particle.x += particle.v

            # floor/cap positions to remain in bounds
            for q, (_, b) in enumerate(bounds):
                b_low, b_high = b
                if particle.x[q] > b_high:
                    particle.x[q] = b_high
                elif particle.x[q] < b_low:
                    particle.x[q] = b_low

            # update particle position if better
            f_x = f(*particle.x)
            f_p = f(*particle.p)
            if f_x < f_p:
                if verbose:
                    ps = '%d: (particle: %d) best position updated | ' % (i, j)
                    args = (particle.p, particle.x, f_p, f_g)
                    ps += 'p = %s -> x = %s [f(p) = %.6f; f(g) = %.6f]' % args
                    print ps
                particle.p = particle.x.copy()
                f_p = f(*particle.p)

                # update global position if better
                if f_p < f_g:
                    if verbose:
                        ps = '%d: new global best (particle: %d) | ' % (i, j)
                        args = (g, particle.p, f_p, f_g)
                        ps += 'g = %s -> p = %s [f(p) = %s; f(g) = %s]' % args
                        print ps

                    g = particle.p.copy()
                    ps = '%d: new global best (particle: %d) | ' % (i, j)
                    ps += 'g = %s; f(g) = %s' % (g, f_g)
                    print ps
                    f_g = f(*g)
        i += 1

    print '\nglobal best after %d iterations = %s\n\n' % (n_iter, g)
    return g


def rosenbrock(x, y):
    # The rosenbrock function: min @ (1, 1 )
    return (1 - x)**2 + 100 * (y - x**2)**2


def matyas(x, y):
    # minimum @ (0, 0)
    return 0.26 * (x**2 + y**2) - 0.48 * x * y


def polynomial(x, y, z, a=1, b=2, c=3):
    # minimum @ (a, b, c)
    return (x - a)**2 + (y - b)**2 + (z - c)**2


if __name__ == '__main__':
    np.random.seed(77)
    swarm_size = 250
    n_iter = 100

    def test_rosenbrock():
        bounds = [
            ('x', [-1, 1.5]),
            ('y', [-2, 3])]
        z = pso(f=rosenbrock, swarm_size=swarm_size, bounds=bounds,
                n_iter=n_iter, omega=0.75, phi_p=0.02, phi_g=0.1)

    def test_matyas():
        bounds = [
            ('x', [-5, 5]),
            ('y', [-5, 5])]
        z = pso(f=matyas, swarm_size=swarm_size, bounds=bounds,
                n_iter=n_iter, omega=0.75, phi_p=0.02, phi_g=0.1)

    def test_3d():
        bounds = [
            ('x', [-250, 500]),
            ('y', [-500, 50]),
            ('z', [-100, 100])]
        z = pso(f=polynomial, swarm_size=swarm_size, bounds=bounds,
                n_iter=n_iter, omega=0.75, phi_p=0.02, phi_g=0.1)

    test_rosenbrock()
    test_matyas()
    test_3d()
