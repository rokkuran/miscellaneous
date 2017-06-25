using Plots


const G = 6.67408e-11
const AU = 149.6e6 * 1000
const M☉ = 1.98855 * 10.0^30
const ONE_DAY = 24*3600


type Body
  mass::Float64
  position::Vector{Float64}
  velocity::Vector{Float64}
  force::Vector{Float64}
  name::String
end


function attraction(self::Body, other::Body)
  r = other.position - self.position
  force = (G * self.mass * other.mass) * r / norm(r)^3
end


kinetic_energy(b::Body) = 0.5 * (b.velocity' * b.velocity)[1]
potential_energy(b::Body) = -b.mass / sqrt((b.position' * b.position)[1])
total_energy(b::Body) = kinetic_energy(b) + potential_energy(b)

function check_energy_conservation(b::Body, E₀::Float64, verbose=false)
  K = kinetic_energy(b)
  U = potential_energy(b)
  E = K + U
  if verbose
    println("$b\nK = $K; U = $U; E = $E")
    println("energy loss = $(E₀ - E)")
    println("relative energy loss = $((E₀ - E)/E₀)\n")
  end
  K, U
end


function update_forces(bodies::Array{Body})
  for b in bodies
    b.force = [0, 0, 0]
  end

  for a in bodies
    for b in bodies
      if a.name != b.name
        force = attraction(a, b)
        a.force += force
        b.force -= force
      end
    end
  end
  bodies
end


function move_old(bodies::Array{Body}, Δt::Real)
  # old, incorrect
  bodies = update_forces(bodies)
  for b in bodies
    # wrong way around, but appoximate
    b.velocity += (b.force / b.mass) * Δt
    b.position += b.velocity * Δt
  end
  bodies
end

# function move(bodies, Δt)
function move_euler(bodies::Array{Body}, Δt::Real)
  # forward euler
  bodies = update_forces(bodies)
  for b in bodies
    b.position += b.velocity * Δt
  end

  bodies = update_forces(bodies)
  for b in bodies
    b.velocity += (b.force / b.mass) * Δt
  end
  bodies
end


function move(bodies::Array{Body}, Δt::Real)
# function move_leapfrog(bodies, Δt)
  bodies = update_forces(bodies)
  for b in bodies
    b.velocity += (b.force / b.mass) * 0.5 * Δt
    b.position += b.velocity * Δt
  end

  bodies = update_forces(bodies)
  for b in bodies
    b.velocity += (b.force / b.mass) * 0.5 * Δt
  end
  bodies
end


function simulate(bodies::Array{Body}, N::Int64=1000, Δt::Real=ONE_DAY)
  points = Dict(b.name=>b.position' for b in bodies)

  E₀ = Dict(b.name=>total_energy(b) for b in bodies)
  K = Dict(b.name=>[kinetic_energy(b)] for b in bodies)
  U = Dict(b.name=>[potential_energy(b)] for b in bodies)

  for i in 1:N
    bodies = move(bodies, Δt)
    for b in bodies
      points[b.name] = vcat(points[b.name], b.position')

      push!(K[b.name], kinetic_energy(b))
      push!(K[b.name], potential_energy(b))

      if i % 1 == 0
        E_loss = (E₀[b.name] - (K[b.name][end] + U[b.name][end]))
        println("$i:$N $(b.name) | energy loss $E_loss")
      end
    end
    # i % 5000 == 0 && println("$i:$N")
  end
  bodies, points
end


function plot_orbits(bodies::Array{Body}, points, colours, output::String, s=1:1:N)
  for (i, (b, c)) in enumerate(zip(bodies, colours))
    if i == 1
      plot(points[b.name][:, 1][s], points[b.name][:, 2][s], line=nothing,
           marker=(:circle, 3, 0.33, c, stroke(0)), label=b.name)
    else
      plot!(points[b.name][:, 1][s], points[b.name][:, 2][s], line=nothing,
            marker=(:circle, 2, 0.33, c, stroke(0)), label=b.name)
    end
  end
  plot!(legend=nothing, formatter=:scientific)
  savefig(output)
end


function create_gif(N::Int64)
  x_min, x_max = extrema(append!(points["earth"][:, 1], points["venus"][:, 1]))
  y_min, y_max = extrema(append!(points["earth"][:, 2], points["venus"][:, 2]))

  anim = @animate for i=1:N
    plot(
      [points["sun"][:, 1][i]], [points["sun"][:, 2][i]],
      line=nothing,
      marker=(:circle, 15, :red, stroke(0)),
      label="sun"
    )
    plot!(
      [points["venus"][:, 1][i]], [points["venus"][:, 2][i]],
      line=nothing,
      marker=(:circle, 5, :purple, stroke(0)),
      label="venus"
    )
    plot!(
      [points["earth"][:, 1][i]], [points["earth"][:, 2][i]],
      line=nothing,
      marker=(:circle, 7, :blue, stroke(0)),
      label="earth"
    )
    plot!(xlim=(x_min, x_max), ylim=(y_min, y_max))
  end
  gif(anim, "$path/orbits.gif", fps = 15)
  nothing
end


function main()
  sun = Body(M☉, [0, 0, 0], [0, 0, 0], [0, 0, 0], "sun")
  mercury = Body(3.285e23, [0, 5.7e10, 0], [47000, 0, 0], [0, 0, 0], "mercury")
  mars = Body(2.4e24, [0, 2.2e11, 0], [24000, 0, 0], [0, 0, 0], "mars")
  earth = Body(5.9742e24, [-1*AU, 0, 0], [0, 29.783*1000, 0], [0, 0, 0], "earth")
  venus = Body(4.8685e24, [0.723 *AU, 0, 0], [0, -35.0*1000, 0], [0, 0, 0], "venus")
  jupiter = Body(1e28, [0, 7.7e11, 0], [13000, 0, 0], [0, 0, 0], "jupiter")
  saturn = Body(5.7e26, [0, 1.4e12, 0], [9000, 0, 0], [0, 0, 0], "saturn")
  uranus = Body(8.7e25, [0, 2.8e12, 0], [6835, 0, 0], [0, 0, 0], "uranus")
  neptune = Body(1e26, [0, 4.5e12, 0], [5477, 0, 0], [0, 0, 0], "neptune")
  pluto = Body(1.3e22, [0, 3.7e12, 0], [4748, 0, 0], [0, 0, 0], "pluto")

  bodies = [sun, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune, pluto]
  colours = [:yellow, :orange, :purple, :blue, :red, :brown, :grey, :green, :pink, :cyan]


  N = 100
  n_samples = 100
  s = 1:round(Int, N/n_samples):N

  path = "/home/rokkuran/workspace/miscellaneous/nbody/output"
  # output = "$path/orbits_euler_$N.png"
  output = "$path/orbits_leapfrog_$N.png"
  bodies = [sun, mercury, venus, earth]#, mars, jupiter, saturn, uranus, neptune, pluto]
  colours = [:yellow, :orange, :purple, :blue]#, :red, :brown, :grey, :green, :pink, :cyan]

  bodies, points = simulate(bodies, N, ONE_DAY)
  plot_orbits(bodies, points, colours, output, s)
end

main()
