import Base.copy
using Distributions


type Bat
  x::Array{Float64}
  ν::Array{Float64}
  A::Float64
  r::Float64
  fitness::Float64
end

Base.copy(m::Bat) = Bat(copy(m.x), copy(m.ν), copy(m.A), copy(m.r), copy(m.fitness))


function create_bat(f, search_space)
  x = []
  for bound in search_space
    push!(x, rand(Uniform(bound...)))
  end
  # A and r initialisations from:
  # Xin-She Yang, Bat Algorithm and Cuckoo Search: A Tutorial
  Bat(x, zeros(length(x)), rand(Uniform(1, 2)), rand(), f(x...))
end


# function create_bat_population(n, f, search_space, A, r)
function create_bat_population(n, f, search_space)
  # [create_bat(f, search_space, A, r) for _ in 1:n]
  [create_bat(f, search_space) for _ in 1:n]
end


n_best_bats(bats, n) = sort(bats, by=z->z.fitness)[1:n]
get_best_bat(bats) = n_best_bats(bats, 1)[1]


β(f_min, f_max, d) = rand(Uniform(f_min, f_max), d)
frequency(f_min, f_max, d) = f_min + (f_min - f_max) * β(f_min, f_max, d)


function enforce_bounds(x, search_space, verbose=false)
  for bound in search_space
    b_min, b_max = bound
    for (i, z) in enumerate(x)
      if z < b_min
        x[i] = b_min
        verbose && println("\tbounds update: $z -> $b_min")
      end
      if z > b_max
        x[i] = b_max
        verbose && println("\tbounds update: $z -> $b_max")
      end
    end
  end
  return x
end


mean_loudness(bats) = mean([b.A for b in bats])


# function move_bats(bats, f, f_min, f_max, r, γ, A, α, search_space, verbose=true)
function move_bats(bats, f, f_min, f_max, γ, α, search_space, verbose=true)
  best_bat = get_best_bat(bats)
  updated_bats = []
  g = best_bat.x
  for (i, bat) in enumerate(bats)
    x, ν = bat.x, bat.ν
    ν += (bat.x - g) .* frequency(f_min, f_max, length(x))
    x += bat.ν

    verbose && println("    bat $i: \n\tx: $(bat.x) -> $x \n\tν: $(bat.ν) -> $ν")
    x = enforce_bounds(x, search_space, verbose)

    # generating local bats near global best
    local_bat = Bat(x, ν, bat.A, bat.r, f(x...))
    if rand() > local_bat.r
      # TODO: incorporate loudness to local update
      # local_x = g + 0.001 * rand(Normal(0, 1), length(g))
      verbose && println("\t<A> = $(mean_loudness(bats))")
      local_x = g + rand(Uniform(-1, 1), length(g)) * mean_loudness(bats)
      local_bat = Bat(local_x, ν, local_bat.A, local_bat.r, f(local_x...))
      verbose && println("\n\tlocal update: \n\tx: $(bat.x) -> $(local_bat.x) \n\tfitness: $(bat.fitness) -> $(local_bat.fitness)")
    end

    # TODO: include pulse rate and loudness updates properly
    if (local_bat.fitness <= bat.fitness) & (rand() < local_bat.A)
      local_bat.r *= (1 - exp(-γ))
      local_bat.A *= α
      verbose && println("\tr = $(local_bat.r) | A = $(local_bat.A)")
    end

    if local_bat.fitness < best_bat.fitness
      best_bat = copy(local_bat)
      verbose && println("best bat position updated = $(best_bat.x) | fitness = $(best_bat.fitness)")
    end
    verbose && println("\tr = $(local_bat.r) | A = $(local_bat.A)")
    push!(updated_bats, local_bat)
  end
  updated_bats
end


function bat_algorithm(f, n_bats, n_iter, f_min, f_max, γ, α, search_space, verbose=true)
  bats = create_bat_population(n_bats, f, search_space)

  i = 1
  while i <= n_iter
    verbose && println("\n\niteration $i")
    bats = move_bats(bats, f, f_min, f_max, γ, α, search_space, verbose)
    i += 1
  end

  bb = get_best_bat(bats)
  verbose && println("\n\n$bb")
  verbose && println("min @ ($(bb.x), $(bb.fitness))")
  bb
end


function test_function(f, search_space)
  n_bats = 100
  f_min, f_max = [0, 2]
  # r = 0.01  # pulse rate
  r = 0.1  # pulse rate
  γ = 0.9  # pulse rate scaling factor (for increasing r)
  # γ = 1  # pulse rate scaling factor (for increasing r)
  A = 2  # loudness
  # A = 0.5  # loudness
  α = 0.9  # loudness scaling factor (for decreasing A)
  # α = 1  # loudness scaling factor (for decreasing A)
  n_iter = 50

  bat_algorithm(f, n_bats, n_iter, f_min, f_max, γ, α, search_space, true)
end


rastrigin(x, y) = x^2 + y^2 - cos(18 * x) - cos(18 * y) + 2  # min @ (0, 0)
search_space = Array[[-1, 1], [-1, 1]]
result = test_function(rastrigin, search_space)
println("\nmin @ (0, 0) [rastrigin] result=$(result.x)")
println("$result\n")


function test_all_functions()
  f(x) = -exp(-(x - 1)^2) + 1  # min @ x=1
  search_space = Array[[-5, 5]]
  result = test_function(f, search_space)
  println("\nmin @ 1 [gaussian] | result=$(result.x)")
  println("$result\n")

  rosenbrock(x, y) = (1 - x)^2 + 100 * (y - x^2)^2   # min @ (x, y)=(1, 1)
  search_space = Array[[-1, 1.5], [-2, 3]]
  result = test_function(rosenbrock, search_space)
  println("\nmin @ (1, 1) [rosenbrock] | result=$(result.x)")
  println("$result\n")

  matyas(x, y) = 0.26 * (x^2 + y^2) - 0.48 * x * y  # min @ (x, y)=(0, 0)
  search_space = Array[[-5, 5], [-5, 5]]
  result = test_function(matyas, search_space)
  println("\nmin @ (0, 0) [matyas] result=$(result.x)")
  println("$result\n")

  # minimum @ (a, b, c)
  polynomial(x, y, z, a=1, b=2, c=3) = (x - a)^2 + (y - b)^2 + (z - c)^2
  search_space = Array[[-5, 7], [-2, 14], [-9, 10]]
  result = test_function(polynomial, search_space)
  println("\nmin @ (1, 2, 3) [polynomial] result=$(result.x)")
  println("$result\n")


  rastrigin(x, y) = x^2 + y^2 - cos(18 * x) - cos(18 * y) + 2  # min @ (0, 0)
  search_space = Array[[-1, 1], [-1, 1]]
  result = test_function(rastrigin, search_space)
  println("\nmin @ (0, 0) [rastrigin] result=$(result.x)")
  println("$result\n")
end


# test_all_functions()
