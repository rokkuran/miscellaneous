using Plots


function strategy(a, k, verbose=false)
  _, best_x = findmax(a)
  verbose && println("best_x=$best_x | $a")
  k_best_x = 0
  for (j, x) in enumerate(a)
    if j <= k
      if x > k_best_x
        k_best_x = x
      end
      verbose && println("j=$j; x=$x; k_best_x=$k_best_x | k=$k")
    else
      verbose && println("j=$j; x=$x; k_best_x=$k_best_x")
      if x > k_best_x
        verbose && println("chosen = $j | k_best_x=$k_best_x\n")
        return j, best_x, k_best_x  # toilet chosen is at index j in a
      end
    end
  end
  verbose && println("chosen = $(length(a)) | k_best_x=$k_best_x\n")
  return length(a), best_x, k_best_x
end


function simulate(a, k, n_iter)
  outcomes = []
  i = 1
  while i <= n_iter
    shuffle!(a)
    chosen, best_toilet, k_best = strategy(toilets, k)
    push!(outcomes, strategy(a, k))
    i += 1
  end

  best_chosen_count = 0
  for (i, (chosen, best, k_best)) in enumerate(outcomes)
    if chosen == best
      best_chosen_count += 1
    end
  end

  pc_chosen_best = best_chosen_count / n_iter
  return pc_chosen_best
end


n = 100
toilets = collect(1:n)

n_iter = 1000000
ks = 1:n

p = []
println("\nPercentage best toilet was chosen for various k:")
for k in ks
  pc_chosen_best = simulate(toilets, k, n_iter)
  push!(p, pc_chosen_best)
  println("k = $k | $pc_chosen_best")
end


plot(ks, p)
plot!(title="n=$n; n_iter=$n_iter | max @ $(reverse(findmax(p)))")
plot!(xlabel="k", ylabel="% times best toilet chosen", legend=nothing)

path = "/home/rokkuran/workspace/miscellaneous/math_misc"
savefig("$path/choosing_best_toilet_n=$(n)_n_iter=$(n_iter).png")
