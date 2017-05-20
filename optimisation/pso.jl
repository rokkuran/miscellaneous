using Distributions


type Particle
  x::Array{Float64}  # position
  p::Array{Float64}  # best known position
  v::Array{Float64}  # velocity
  Particle(x, v) = new(x, x, v)
end


function create_particle(f, search_space)
  x, v = [], []
  for bound in search_space
    b_low, b_high = bound
    push!(x, rand(Uniform(bound...)))
    push!(v, rand(Uniform(-abs(b_high - b_low), abs(b_high - b_low))))
  end
  Particle(x, v)
end


function status(msg, i, j, from, to, f_to)
  println("$i: $j $msg | $from -> $to [f = $f_to]")
end


function pso(f, swarm_size, bounds, n_iter=50, ω=0.75, ϕp=0.02, ϕg=0.1, verbose=false)
  verbose && println("running particle swarm optimisation...\n\n")
  verbose && println("swarm_size = $swarm_size\nn_iter = $n_iter\nω=$ω\nϕp = $ϕp\nϕg = $ϕg\n")

  particles = [create_particle(f, bounds) for _ in 1:swarm_size]

  #TODO: there must be a more elegant way to acheive this??
  g = particles[1].p
  for (i, particle) in enumerate(particles[2:end])
    if f(particle.p...) < f(g...)
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

      if f(particle.x...) < f(particle.p...)
        verbose && status("particle best position update", i, j, particle.p, particle.x, f(particle.p...))
        particle.p = particle.x
        if f(particle.p...) < f(g...)
          verbose && status("new global best", i, j, g, particle.x, f(particle.p...))
          g = particle.p
        end
      end
    end
    i += 1
  end
  return g
end


function test_function(f, bounds)
  swarm_size = 100
  n_iter = 50
  ω = 0.75
  ϕp = 0.02
  ϕg = 0.1

  pso(f, swarm_size, bounds, n_iter, ω, ϕp, ϕg)
end


function test_all_functions()
  f(x) = -exp(-(x - 1)^2) + 1  # min @ x=1
  search_space = Array[[-5, 5]]
  result = test_function(f, search_space)
  println("\nmin @ 1 [gaussian] | result=$result")

  rosenbrock(x, y) = (1 - x)^2 + 100 * (y - x^2)^2   # min @ (x, y)=(1, 1)
  search_space = Array[[-1, 1.5], [-2, 3]]
  result = test_function(rosenbrock, search_space)
  println("\nmin @ (1, 1) [rosenbrock] | result=$result")

  matyas(x, y) = 0.26 * (x^2 + y^2) - 0.48 * x * y  # min @ (x, y)=(0, 0)
  search_space = Array[[-5, 5], [-5, 5]]
  result = test_function(matyas, search_space)
  println("\nmin @ (0, 0) [matyas] result=$result")

  # minimum @ (a, b, c)
  polynomial(x, y, z, a=1, b=2, c=3) = (x - a)^2 + (y - b)^2 + (z - c)^2
  search_space = Array[[-5, 7], [-2, 14], [-9, 10]]
  result = test_function(polynomial, search_space)
  println("\nmin @ (1, 2, 3) [polynomial] result=$result")

  rastrigin(x, y) = x^2 + y^2 - cos(18 * x) - cos(18 * y) + 2  # min @ (0, 0)
  search_space = Array[[-1, 1], [-1, 1]]
  result = test_function(rastrigin, search_space)
  println("\nmin @ (0, 0) [rastrigin] result=$result")
end


test_all_functions()
