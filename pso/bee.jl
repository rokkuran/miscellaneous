import Base.copy
using Distributions


type Bee
  position
  value
end

Base.copy(m::Bee) = Bee(copy(m.position), copy(m.value))


function create_scout_bee(f, search_space, dimensions)
  position = rand(Uniform(search_space...), dimensions)
  Bee(position, f(position...))
end


function create_scout_bees(n, f, search_space)
  [create_scout_bee(f, search_space, 1) for _ in 1:n]
end


get_n_best_bees(bees, n) = sort(bees, by=x->x.value)[1:n]
get_best_bee(bees) = get_n_best_bees(bees, 1)[1]


function recruit_forager_bees(f, bee, n, ngh, search_space)
  ss_min, ss_max = search_space
  forager_bees = [bee]  # include original bee
  for _ in 1:n
    Δx = rand(size(bee.position)) * ngh
    fbx = rand() < 0.5 ? bee.position + Δx : bee.position - Δx
    #TODO: this will need to be fixed for multidimensional spaces
    if fbx[1] < ss_min[1]
      fbx = ss_min
    elseif fbx[1] > ss_max[1]
      fbx = ss_max
    end
    push!(forager_bees, Bee(fbx, f(fbx...)))
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
search_space = [-5, 5]

result = bee_algorithm(f, n, m, e, nep, nsp, ngh, max_iter, ngh_scaling_factor, search_space)
println("\n\nresult=$result")
