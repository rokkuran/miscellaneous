import Base.copy
using Distributions


type Bat
  x::Array{Float64}
  ν::Array{Float64}
  fitness::Float64
end
Bat(x, f) = Bat(x, zeros(length(x)), f(x...))
# Bat(x, f) = Bat(x, zeros(length(x)), f(x...))
# Bat(x, ν, f) = Bat(x, ν, f(x...))

# w(x, y) = x^ + y^2
# a = [1., 2.]
# q = Bat(a, zeros(length(a)), w)

Base.copy(m::Bat) = Bat(copy(m.x), copy(m.ν), copy(m.fitness))


function create_bat(f, search_space)
  x = []
  for bound in search_space
    push!(x, rand(Uniform(bound...)))
  end
  # println("$x | $(zeros(length(x))) | $(f(x...))")
  # Bat(x, zeros(length(x)), f(x...))
  Bat(x, f)
end


function create_bat_population(n, f, search_space)
  [create_bat(f, search_space) for _ in 1:n]
end


n_best_bats(bats, n) = sort(bats, by=z->z.fitness)[1:n]
get_best_bat(bats) = n_best_bats(bats, 1)[1]


β(f_min, f_max, d) = rand(Uniform(f_min, f_max), d)
frequency(f_min, f_max, d) = f_min + (f_max - f_min) * β(f_min, f_max, d)


function adhere_to_bounds(x, search_space)
  for bound in search_space
    b_min, b_max = bound
    for (i, z) in enumerate(x)
      if z < b_min
        x[i] = b_min
        println("\tbounds update: $z -> $b_min")
      end
      if z > b_max
        x[i] = b_max
        println("\tbounds update: $z -> $b_max")
      end
    end
  end
  return x
end


best_bat_x(bats) = get_best_bat(bats).x


# function move_bats(bats, f, f_min, f_max, r, γ, A, α, search_space, verbose=true)
#   best_bat = get_best_bat(bats)
#   updated_bats = []
#   for (i, bat) in enumerate(bats)
#     # g = copy(best_bat.x)
#
#     x, ν = bat.x, bat.ν
#     # println("$i: x=$x; ν=$ν")
#     bat.ν += (x - best_bat.x) .* frequency(f_min, f_max, length(x))
#     bat.x += ν
#     if verbose
#       println("    bat $i: \n\tx: $x -> $(bat.x) \n\tν: $ν -> $(bat.ν)")
#     end
#     bat.x = adhere_to_bounds(bat.x, search_space)
#     bat.fitness = f(bat.x...)
#
#     # generating local bats near global best
#     local_bat = copy(bat)
#     if rand() > r
#       local_bat.x = best_bat.x + 0.01 * rand(Normal(), length(best_bat.x))
#       local_bat.fitness = f(local_bat.x...)
#       if verbose
#         println("\n\tlocal update: \n\tx: $(bat.x) -> $(local_bat.x) \n\tfitness: $(bat.fitness) -> $(local_bat.fitness)\n")
#       end
#     end
#
#     # update if solution improves or not too loud
#     if (local_bat.fitness <= bat.fitness) & (rand() < A)
#       bat = copy(local_bat)
#       # r *= (1 - exp(-γ))
#       r *= γ
#       A *= α
#       println("\tr = $r | A = $A")
#     end
#
#     if bat.fitness < best_bat.fitness
#       best_bat = copy(bat)
#       println("    best bat position updated = $(best_bat.x) | fitness = $(best_bat.fitness)\n")
#     end
#
#     push!(updated_bats, bat)
#   end
#   println("    \nbest bat position = $(best_bat.x) | fitness = $(best_bat.fitness)")
#   updated_bats, r, A
# end

function move_bats(bats, f, f_min, f_max, r, γ, A, α, search_space, verbose=true)
  best_bat = get_best_bat(bats)
  updated_bats = []
  g = best_bat.x
  for (i, bat) in enumerate(bats)
    x, ν = bat.x, bat.ν
    ν += (bat.x - g) .* frequency(f_min, f_max, length(x))
    x += bat.ν
    if verbose
      println("    bat $i: \n\tx: $(bat.x) -> $x \n\tν: $(bat.ν) -> $ν")
    end
    x = adhere_to_bounds(x, search_space)

    # generating local bats near global best
    # local_bat = Bat(x, ν, f(x...))
    local_bat = Bat(x, f)
    if rand() > r
      local_x = g + 0.001 * rand(Normal(), length(g))
      # local_bat = Bat(local_x, ν, f(x...))
      local_bat = Bat(local_x, f)
      if verbose
        println("\n\tlocal update: \n\tx: $(bat.x) -> $(local_bat.x) \n\tfitness: $(bat.fitness) -> $(local_bat.fitness)")
      end
    end

    # update if solution improves or not too loud
    if (local_bat.fitness <= bat.fitness) & (rand() < A)
      # r *= (1 - exp(-γ))
      r *= γ
      A *= α
      if verbose
        println("\tr = $r | A = $A")
      end
    else
    end

    if local_bat.fitness < best_bat.fitness
      best_bat = copy(local_bat)
      println("$i: best bat position updated = $(best_bat.x) | fitness = $(best_bat.fitness)")
    end

    push!(updated_bats, local_bat)
  end
  # println("    \nbest bat position = $(best_bat.x) | fitness = $(best_bat.fitness)")
  updated_bats, r, A
end



# function generate_local_bats(bat, g, r)
#   # g = best_bat_x(bats)
#   # println("  generating local bats:")
#   # for (i, bat) in enumerate(bats)
#     local_bat = bat
#     if rand() > r
#       local_bat.x = g + 0.001 * rand(Uniform(0, 1), length(g))
#       # println("    bat $i: \n\tx: $x -> $(bat.x)")
#     end
#   # end
#   bats
# end


n = 50
f_min, f_max = [0, 2]
# r = 0.01  # pulse rate
r = 0.5  # pulse rate
# γ = 0.9  # pulse rate scaling factor (for increasing r)
γ = 1  # pulse rate scaling factor (for increasing r)
# A = 2  # loudness
A = 0.5  # loudness
# α = 0.9  # loudness scaling factor (for decreasing A)
α = 1  # loudness scaling factor (for decreasing A)

n_iter = 20

f(x) = -exp(-(x - 1)^2) + 1  # min @ x=1
search_space = Array[[0, 2]]


bats = create_bat_population(n, f, search_space)
# println(bats)

i = 1
while i <= n_iter
  println("\n\niteration $i")
  bats, r, A = move_bats(bats, f, f_min, f_max, r, γ, A, α, search_space, false)
  # println("\n\n$bats")
  i += 1
end
