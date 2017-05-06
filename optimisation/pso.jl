using Distributions


type Particle
  x  # position
  p  # best known position
  v  # velocity
  Particle(x, v) = new(x, x, v)
end

type Bounds
  low
  high
  Bounds(low, high) = new(low, high)
end

# uniform(a, b, dim) = rand(dim...) * (b - a) - a

function status(msg, i, j, from, to, f_to)
  println("$i: $j $msg | $from -> $to [f = $f_to]")
end


function pso(f, swarm_size, bounds, n_iter=50, ω=0.75, ϕp=0.02, ϕg=0.1)
  println("running particle swarm optimisation...\n\n")
  println("swarm_size = $swarm_size\nn_iter = $n_iter\nω=$ω\nϕp = $ϕp\nϕg = $ϕg\n")

  b_low, b_high = bounds
  x = rand(Uniform(b_low, b_high), swarm_size...)
  p = copy(x)
  v = rand(Uniform(-abs(b_high - b_low), abs(b_high - b_low)), swarm_size...)

  particles = [Particle(x[i], v[i]) for i in 1:swarm_size]

  # there must be a more elegant way to acheive this??
  g = particles[1].p
  for (i, particle) in enumerate(particles[2:end])
    if f(particle.p) < f(g)
      g = particle.p
    end
  end

  i = 0
  while i < n_iter
    for (j, particle) in enumerate(particles)
      rp, rg = rand(Uniform(0, 1), 2)
      particle.v = ω * particle.v
      particle.v += ϕp * rp * (particle.p - particle.x)
      particle.v += ϕg * rg * (g - particle.x)

      particle.x += particle.v

      if f(particle.x) < f(particle.p)
        status("particle best position update", i, j, particle.p, particle.x, f(particle.p))
        particle.p = particle.x
        if f(particle.p) < f(g)
          status("new global best", i, j, g, particle.x, f(particle.p))
          g = particle.p
        end
      end
    end
    i += 1
  end
  return g
end


f(x) = -exp(-(x - 0.8)^2)
swarm_size = 100
n_iter=50
ω=0.75
ϕp=0.02
ϕg=0.1
bounds = [-5, 5]

z = pso(f, swarm_size, bounds, n_iter, ω, ϕp, ϕg)
println("\nglobal best after $n_iter iterations = $z")
