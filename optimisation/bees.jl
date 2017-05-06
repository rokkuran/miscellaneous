import Base.copy
using Distributions


type Bee
  position
  value
end

Base.copy(m::Bee) = Bee(copy(m.position), copy(m.value))


function create_scout_bee(f, search_space)
  x = []
  for bound in search_space
    push!(x, rand(Uniform(bound...)))
  end
  Bee(x, f(x...))
end


function create_scout_bees(n, f, search_space)
  [create_scout_bee(f, search_space) for _ in 1:n]
end


get_n_best_bees(bees, n) = sort(bees, by=x->x.value)[1:n]
get_best_bee(bees) = get_n_best_bees(bees, 1)[1]


function recruit_forager_bees(f, bee, n, ngh, search_space)
  forager_bees = [bee]  # include original bee
  for _ in 1:n
    Δx = rand(size(bee.position)) * ngh
    x = rand() < 0.5 ? bee.position + Δx : bee.position - Δx
    for bound in search_space
      b_min, b_max = bound
      for (i, v) in enumerate(x)
        if v < b_min
          x[i] = b_min
        end
        if v > b_max
          x[i] = b_max
        end
      end
    end
    push!(forager_bees, Bee(x, f(x...)))
  end
  forager_bees
end


function best_neighbour_bees(bees, f, n_bees, ngh, search_space)
  new_best_local_bees = []
  for bee in bees
    forager_bees = recruit_forager_bees(f, bee, n_bees, ngh, search_space)
    best_local_bee = get_n_best_bees(forager_bees, 1)
    push!(new_best_local_bees, best_local_bee)
  end
  new_best_local_bees = vcat(new_best_local_bees...)
end


function bee_algorithm(f, n, m, e, nep, nsp, ngh, n_iter, ngh_scaling_factor, search_space, verbose=true)
  i = 0
  error = 77.
  best_bee = 0
  while i < n_iter
    if i == 0
      # create initial bee population
      bees = create_scout_bees(n, f, search_space)
      best_bee = get_best_bee(bees)
      if verbose
        println("best_bee = $best_bee")
      end
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

    best_bee = copy(new_best_bee)
    if verbose
      println("$i: best_bee=$best_bee | ngh=$ngh; error=$error")
    end
    ngh *= ngh_scaling_factor
    i += 1
  end
  return best_bee.position
end


function test_function(f, search_space)
  n = 50  # population of bees
  m = 15  # number of best patches
  e = 3  # number of elite patches
  nep = 12  # number of forager bees recruited to elite best patches
  nsp = 8  # number of forager bees recruited around the non-elite best patches
  ngh = 1  # neigbourhood patch size
  n_iter = 50

  ngh = 1
  ngh_scaling_factor = 0.75

  bee_algorithm(f, n, m, e, nep, nsp, ngh, n_iter, ngh_scaling_factor, search_space, false)
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

end


test_all_functions()
