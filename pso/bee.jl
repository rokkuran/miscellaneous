using Distributions


type Bee
  position
  value
end


n = 50  # population size
m = 15  # best patch size
e = 3  # elite patch size
nep = 12  # number of forager bees recruited to elite sites
nsp = 8  # number of forager bees recruited around the non-elite best patches
ngh = 1  # neigbourhood size
max_iter = 10
epsilon = 0.001  # tolerance

search_space = [0, 1]

f(x) = -exp(-(x - 0.8)^2)


function create_scout_bee(f, search_space, dimensions)
  position = rand(Uniform(search_space...), dimensions)
  Bee(position, f(position...))
end

println(create_scout_bee(f, search_space, 1))

# create bee population
bees = [create_scout_bee(f, search_space, 1) for _ in 1:n]
# println(bees)


get_n_best_bees(bees, n) = sort(bees, by=x->x.value)[1:n]
best_bee = get_n_best_bees(bees, 1)
println("best_bee = $best_bee")


best_bees = get_n_best_bees(bees, m)
elite_bees = best_bees[1:e]
non_elite_bees = best_bees[e+1:m]

patch_size = 3
patch_scaling_factor = 0.95

function recruit_forager_bees(f, bee, n, patch_size, search_space)
  ss_min, ss_max = search_space
  forager_bees = []
  # for bee in bees
  for _ in 1:n
    Δx = rand(size(bee.position)) * patch_size
    fbx = rand() < 0.5 ? bee.position + Δx : bee.position - Δx
    # println("Δx = $Δx | fbx = $fbx")
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

# forager_bees = recruit_forager_bees(f, elite_bees, patch_size, search_space)
# println("forager_bees:\n$forager_bees")

# new_elite_bees = []
# for bee in elite_bees
#   efb = recruit_forager_bees(f, bee, nep, patch_size, search_space)
#   new_best_elite_bee = get_n_best_bees(efb, 1)
#   push!(new_elite_bees, new_best_elite_bee)
# end
# new_elite_bees = vcat(new_elite_bees...)
# println("new_elite_bees:\n$new_elite_bees")


function best_neighbour_bees(bees, f, n_bees, patch_size, search_space)
  new_best_local_bees = []
  for bee in bees
    fb = recruit_forager_bees(f, bee, n_bees, patch_size, search_space)
    best_local_bee = get_n_best_bees(fb, 1)
    push!(new_best_local_bees, best_local_bee)
  end
  new_best_local_bees = vcat(new_best_local_bees...)
end

new_elite_bees = best_neighbour_bees(elite_bees, f, nep, patch_size, search_space)
new_non_elite_bees = best_neighbour_bees(non_elite_bees, f, nsp, patch_size, search_space)

println("new_elite_bees: $(size(new_elite_bees))\n$new_elite_bees")
println("new_non_elite_bees: $(size(new_non_elite_bees))\n$new_non_elite_bees")

new_best_bees = vcat(new_elite_bees, new_non_elite_bees)
best_bee = get_n_best_bees(new_best_bees, 1)
println("new_best_bee = $best_bee")
