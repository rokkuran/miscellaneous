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
ngh = 1  # neibourhood size
max_iter = 10
epsilon = 0.001  # tolerance

search_space = [-2, 2]

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

elite_forager_bees = []
for bee in elite_bees
  efb = recruit_forager_bees(f, bee, nep, patch_size, search_space)
  push!(elite_forager_bees, efb)
end
elite_forager_bees = vcat(elite_forager_bees...)
println("elite_forager_bees:\n$elite_forager_bees")

non_elite_forager_bees = []
for bee in non_elite_bees
  nefb = recruit_forager_bees(f, bee, nsp, patch_size, search_space)
  push!(non_elite_forager_bees, nefb)
end
non_elite_forager_bees = vcat(non_elite_forager_bees...)
println("non_elite_forager_bees:\n$non_elite_forager_bees")
