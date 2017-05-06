using Distributions


type Bee
  position
  value
end


function create_scout_bee(f, search_space, dimensions)
  position = rand(Uniform(search_space...), dimensions)
  Bee(position, f(position...))
end


function create_scout_bees(n, f, search_space)
  [create_scout_bee(f, search_space, 1) for _ in 1:n]
end


get_n_best_bees(bees, n) = sort(bees, by=x->x.value)[1:n]


function recruit_forager_bees(f, bee, n, patch_size, search_space)
  ss_min, ss_max = search_space
  forager_bees = [bee]
  for _ in 1:n
    Δx = rand(size(bee.position)) * patch_size
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


function best_neighbour_bees(bees, f, n_bees, patch_size, search_space)
  new_best_local_bees = []
  for bee in bees
    fb = recruit_forager_bees(f, bee, n_bees, patch_size, search_space)
    best_local_bee = get_n_best_bees(fb, 1)
    push!(new_best_local_bees, best_local_bee)
  end
  new_best_local_bees = vcat(new_best_local_bees...)
end



n = 50  # population size
m = 15  # best patch size
e = 3  # elite patch size
nep = 12  # number of forager bees recruited to elite sites
nsp = 8  # number of forager bees recruited around the non-elite best patches
ngh = 1  # neigbourhood size
max_iter = 10
epsilon = 0.001  # tolerance

patch_size = 1
patch_scaling_factor = 0.95

f(x) = -exp(-(x - 0.8)^2)
search_space = [0, 1]


i = 0
while i < max_iter
  if i == 0
    # create initial bee population
    bees = create_scout_bees(n, f, search_space)
    best_bee = get_n_best_bees(bees, 1)
    println("best_bee = $best_bee")
  end

  best_bees = get_n_best_bees(bees, m)
  e_bees = best_bees[1:e]  # elite bees
  ne_bees = best_bees[e+1:m]  # non-elite bees

  new_e_bees = best_neighbour_bees(e_bees, f, nep, patch_size, search_space)
  new_ne_bees = best_neighbour_bees(ne_bees, f, nsp, patch_size, search_space)
  #
  # println("new_elite_bees: $(size(new_elite_bees))\n$new_elite_bees")
  # println("new_non_elite_bees: $(size(new_non_elite_bees))\n$new_non_elite_bees")

  new_best_bees = vcat(new_e_bees, new_ne_bees)
  # println("best_bee = $(get_n_best_bees(new_best_bees, 1))")
  new_scout_bees = create_scout_bees(n-m, f, search_space)
  bees = vcat(new_best_bees, new_scout_bees)
  # println(size(bees))

  println("$i: best_bee=$(get_n_best_bees(new_best_bees, 1)) | patch_size=$patch_size")

  patch_size *= patch_scaling_factor
  i += 1
end
