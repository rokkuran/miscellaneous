using Plots
plotly()


type Body
  mass::Float64
  position::Vector{Float64}
  velocity::Vector{Float64}
end

function to_string(body::Body)
  println("mass = $(body.mass); position = $(body.position); velocity = $(body.velocity)")
end

kinetic_energy(b::Body) = 0.5 * (b.velocity' * b.velocity)[1]
potential_energy(b::Body) = -b.mass / sqrt((b.position' * b.position)[1])
total_energy(b::Body) = kinetic_energy(b) + potential_energy(b)

function check_energy_conservation(b::Body, E₀::Float64)
  K = kinetic_energy(b)
  U = potential_energy(b)
  E = K + U
  println("$b\nK = $K; U = $U; E = $E")
  println("energy loss = $(E₀ - E)")
  println("relative energy loss = $((E₀ - E)/E₀)\n")
end

acceleration(b::Body) = b.position * (-b.mass / norm(b.position)^3)

function forward_euler(b::Body, Δt)
  # forward Euler integration
  a = acceleration(b)
  b.position += b.velocity * Δt
  b.velocity += a * Δt
  b
end

function leapfrog(b::Body, Δt)
  # 2nd order Leapfrog integration - energy conservation built in.
  b.velocity += acceleration(b) * 0.5 * Δt
  b.position += b.velocity * Δt
  b.velocity += acceleration(b) * 0.5 * Δt
  b
end

function runge_kutta_2(b::Body, Δt)
  x = b.position
  half_velocity = b.velocity + acceleration(b) * 0.5 * Δt
  b.position += b.velocity * 0.5 * Δt
  b.velocity += acceleration(b) * Δt
  b.position = x + half_velocity * Δt
  b
end

function runge_kutta_4(b::Body, Δt)
  x = b.position
  a₀ = acceleration(b)
  b.position = x + b.velocity * 0.5 * Δt + a₀ * 0.125 * Δt^2
  a₁ = acceleration(b)
  b.position = x + b.velocity * Δt + a₁ * 0.5 * Δt^2
  a₂ = acceleration(b)
  b.position = x + b.velocity * Δt + (a₀ + 2*a₁) * (1/6.) * Δt^2
  b.velocity += (a₀ + 4*a₁ + a₂) * (1/6.) * Δt
  b
end

function yoshida_6(b::Body, Δt)
  d = [0.784513610477560e0, 0.235573213359357e0, -1.17767998417887e0,
       1.31518632068391e0]
  for i in 1:3
    b = leapfrog(b, Δt * d[i])
  end
  b = leapfrog(b, Δt * d[4])
  for i in 3:-1:1
    b = leapfrog(b, Δt * d[i])
  end
  b
end

function yoshida_8(b::Body, Δt)
  d = [0.104242620869991e1, 0.182020630970714e1, 0.157739928123617e0,
       0.244002732616735e1, -0.716989419708120e-2, -0.244699182370524e1,
       -0.161582374150097e1, -0.17808286265894516e1]

  for i in 1:7
    b = leapfrog(b, Δt * d[i])
  end
  b = leapfrog(b, Δt * d[8])
  for i in 7:-1:1
    b = leapfrog(b, Δt * d[i])
  end
  b
end


function simulate(ns::Int64, Δt::Float64, b::Body, verbose=true)
  E₀ = total_energy(b)
  verbose && check_energy_conservation(b, E₀)

  x = Array{Float64}(0, 2)
  for i in 1:ns
    # (i % 100 == 0) && verbose && check_energy_conservation(b, E₀)
    # b = forward_euler(b, Δt)
    # b = leapfrog(b, Δt)
    # b = runge_kutta_2(b, Δt)
    # b = runge_kutta_4(b, Δt)
    # b = yoshida_6(b, Δt)
    b = yoshida_8(b, Δt)
    x = vcat(x, b.position')
  end
  verbose && check_energy_conservation(b, E₀)
  x
end


ns = 10
Δt = 0.02
b = Body(1, [1, 0], [0, 0.5])
path = simulate(ns, Δt, b)

# s = 1:round(Int, ns/500):ns
# plot(path[:, 1][s], path[:, 2][s])
