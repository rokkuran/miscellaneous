import Base.copy
using Distributions


type Bee
  position
  value
end

Base.copy(m::Bee) = Bee(copy(m.position), copy(m.value))


function create_scout_bee(f, search_space)
  position = []
  for bound in search_space
    # println(b)
    push!(position, rand(Uniform(bound...)))
  end
  # println(position)
  # println(f(position...))
  Bee(position, f(position...))
end


function create_scout_bees(n, f, search_space)
  [create_scout_bee(f, search_space) for _ in 1:n]
end


get_n_best_bees(bees, n) = sort(bees, by=x->x.value)[1:n]
get_best_bee(bees) = get_n_best_bees(bees, 1)[1]

column(a, n) = [a[i][n] for i=1:length(a)]

function recruit_forager_bees(f, bee, n, ngh, search_space)
  ss_min, ss_max = search_space
  forager_bees = [bee]  # include original bee
  for _ in 1:n
    # Δx = rand(size(bee.position)) * ngh
    Δx = rand(size(bee.position)) * ngh
    # fbx = rand() < 0.5 ? bee.position + Δx : bee.position - Δx
    x = rand() < 0.5 ? bee.position + Δx : bee.position - Δx

    for bound in search_space
      # println(bound)
      # println(x)
      b_min, b_max = bound
      # for (i, (b, x)) in enumerate(zip(bound, np))
      for (i, v) in enumerate(x)
        # if !(b_min < v < b_max)
        #   println("out of bounds: [before] $bound | x=$x")
        # end
        if v < b_min
          # println("out of bounds: [before] $bound | $v | x=$x")
          x[i] = b_min
          # println("out of bounds:  [after] $bound | $v | x=$x")
        end
        if v > b_max
          # println("out of bounds: [before] $bound | $v | x=$x")
          x[i] = b_max
          # println("out of bounds:  [after] $bound | $v | x=$x")
        end
        # if !(b_min < v < b_max)
        #   println("out of bounds:  [after] $bound | x=$x")
        # end
      end
      println("$x")
    end
    push!(forager_bees, Bee(x, f(x...)))
  end
  forager_bees
end


function best_neighbour_bees(bees, f, n_bees, ngh, search_space)
  new_best_local_bees = []
  for bee in bees
    fb = recruit_forager_bees(f, bee, n_bees, ngh, search_space)
    best_local_bee = get_n_best_bees(fb, 1)
    push!(new_best_local_bees, best_local_bee)
  end
  new_best_local_bees = vcat(new_best_local_bees...)
end


rmse(x::Bee, y::Bee) = sum([i^2 for i in x.position - y.position])^0.5


function bee_algorithm(f, n, m, e, nep, nsp, ngh, max_iter, ngh_scaling_factor, search_space)
  i = 0
  error = 77.
  best_bee = 0
  while i < max_iter #&& error >= ϵ
    if i == 0
      # create initial bee population
      bees = create_scout_bees(n, f, search_space)
      best_bee = get_best_bee(bees)
      println("best_bee = $best_bee")
    end

    best_bees = get_n_best_bees(bees, m)
    e_bees = best_bees[1:e]  # elite bees
    ne_bees = best_bees[e+1:m]  # non-elite bees

    # create forager bees in the neighbourhoods of the best patches and return
    # the best forager bee for each patch.
    new_e_bees = best_neighbour_bees(e_bees, f, nep, ngh, search_space)
    new_ne_bees = best_neighbour_bees(ne_bees, f, nsp, ngh, search_space)

    new_best_bees = vcat(new_e_bees, new_ne_bees)
    new_best_bee = get_best_bee(new_best_bees)
    new_scout_bees = create_scout_bees(n-m, f, search_space)
    bees = vcat(new_best_bees, new_scout_bees)

    error = rmse(new_best_bee, best_bee)
    best_bee = copy(new_best_bee)
    println("$i: best_bee=$best_bee | ngh=$ngh; error=$error")
    ngh *= ngh_scaling_factor
    i += 1
  end
  return best_bee.position
end


n = 50  # population of bees
m = 15  # number of best patches
e = 3  # number of elite patches
nep = 12  # number of forager bees recruited to elite best patches
nsp = 8  # number of forager bees recruited around the non-elite best patches
ngh = 1  # neigbourhood patch size
max_iter = 50
ϵ = 0.001  # tolerance

ngh = 1
ngh_scaling_factor = 0.75

f(x) = -exp(-(x - 0.8)^2)
# search_space = Array[[-5, 5]]

rosenbrock(x, y) = (1 - x)^2 + 100 * (y - x^2)^2   # min @ (1, 1 )
search_space = Array[[-2, 2], [-3, 3]]

a = create_scout_bee(rosenbrock, search_space)
println(a)
result = bee_algorithm(rosenbrock, n, m, e, nep, nsp, ngh, max_iter, ngh_scaling_factor, search_space)


# result = bee_algorithm(f, n, m, e, nep, nsp, ngh, max_iter, ngh_scaling_factor, search_space)
# println("\n\nresult=$result")
