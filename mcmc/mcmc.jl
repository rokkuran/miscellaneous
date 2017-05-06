using Plots
# using PyPlot
using Distributions
pyplot()

beta(x, α, β) = x^(α-1) * (1-x)^(β-1)

function mcmc(N, α, β)
  states = Float32[]
  si = rand()
  for i in 0:N
    push!(states, si)
    sj = rand()
    ap = min(beta(sj, α, β) / beta(si, α, β), 1)  # acceptance probability
    if rand() >= ap ? false : true  # move to proposed state
      si = sj
    end
  end
  return states
end

function plot_beta_mcmc(α, β)
  x = linspace(0, 1, 1000)
  d = Beta(α, β)
  # fig, ax = subplots()
  plot(x, pdf(d, x), "r-", linewidth=2, alpha=0.6)
  # ax[:plot](x, pdf(d, x), "r-", linewidth=2, alpha=0.6)
  # ax[:hist](mcmc(10000, α, β), 75, normed=true, alpha=0.3)
  gui()
end

plot_beta_mcmc(2, 3)
