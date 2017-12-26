using Distributions
using Plots
pyplot()



function initialise_particles(n::Integer, bounds::Tuple)
	a, b = bounds
	[(rand(a:b), rand(a:b)) for _ in 1:n]
end


function move(p::Tuple)
	q = [x for x in p]
	if rand() >= 0.5
		q[1] += rand(-1:2:1)
	else
		q[2] += rand(-1:2:1)
	end
	Tuple(q)
end


function apply_bounds(p, bounds, i)
	q = [x for x in p]
	if p[i] < bounds[1]
		q[i] = bounds[1]
	elseif p[i] > bounds[2]
		q[i] = bounds[2]
	end
	Tuple(q)
end


function enforce_bounds(p, lims)
	for (i, lim) in enumerate(lims)
		p = [apply_bounds(x, lim, i) for x in p]
	end
	p
end


function update_static_points_old(p, static_points)
	dims = length(static_points[1])
	sp = copy(static_points)
	for x in static_points
		d = abs.(p .- x)
		if sum(d) <= dims
			push!(sp, x)

		end
	end
	sp
end


function apply_sticking(p, static_points)
	dims = length(static_points[1])
	new_static = copy(static_points)
	for s in static_points
		d = abs.(p .- s)
		if sum(d) <= dims && p ∉ new_static
			push!(new_static, p)
		end
	end
	new_static	
end


function update_statics(particles, static_points)
	# TODO: bad and inefficient
	new_static = copy(static_points)
	for p in particles
		new_static = apply_sticking(p, static_points)
	end
	new_static	
end


function run_simulation(n_particles, n_iter, bounds; verbose::Bool=false)
	
	particles = initialise_particles(n_particles, bounds)

	static_points = [(0, 0)]
	static_points = update_statics(particles, static_points)

	xlim, ylim = bounds, bounds

	for n in 1:n_iter
		
		verbose && println("$n: n_static = $(length(static_points))")
	
		for i in eachindex(particles)
			verbose && println("\t$i: $(particles[i])\n\t$(static_points)")
			if particles[i] ∉ static_points
				particles[i] = move(particles[i])
				static_points = apply_sticking(particles[i], static_points)
			end
		end

		if n % 1000 == 0
			println("$n: n_particles = $(n_particles); n_static = $(length(static_points))")
		end
		
		particles = enforce_bounds(particles, [xlim, ylim])
	end
	
	particles
end


function sim_gif(n_particles, n_iter, bounds; verbose::Bool=false)
	
	particles = initialise_particles(n_particles, bounds)

	static_points = [(0, 0)]
	static_points = update_statics(particles, static_points)

	xlim, ylim = bounds, bounds

	@gif for n in 1:n_iter
		
		verbose && println("$n: n_static = $(length(static_points))")
	
		for i in eachindex(particles)
			verbose && println("\t$i: $(particles[i])\n\t$(static_points)")
			if particles[i] ∉ static_points
				particles[i] = move(particles[i])
				static_points = apply_sticking(particles[i], static_points)
			end
		end

		if n % 1000 == 0
			println("$n: n_particles = $(n_particles); n_static = $(length(static_points))")
		end
		
		particles = enforce_bounds(particles, [xlim, ylim])

		plot(particles, 
			 l=nothing, 
			 m=(:dot, 3, stroke(0)),
			 legend=nothing, 
			 xlim=bounds, 
			 ylim=bounds,
			 size=(500, 500)
			 )

	end every 50
	
	particles
end


function create_gif()

	n_particles = 250
	n_iter = 1000
	
	bounds = (-100, 100)
	particles = initialise_particles(n_particles, bounds)

	static_points = [(0, 0)]
	
	for p in particles
		static_points = update_static_points(p, static_points)
	end

	xlim, ylim = bounds, bounds

	plot(particles, 
		l=nothing, 
		m=(:dot, stroke(0)), 
		legend=nothing,
		xlim=xlim,
		ylim=ylim)

	@gif for n in 1:n_iter
		
		println("$n: n_static = $(length(static_points))")

		for i in eachindex(particles)
			if particles[i] ∉ static_points
				particles[i] = move(particles[i])
				static_points = update_static_points(particles[i], static_points)
			end

			# println("$n: p = $i; $(particles[i])")
		end
		
		particles = enforce_bounds(particles, [xlim, ylim])
			
		plot(particles, 
			 l=nothing, 
			 m=(:dot, stroke(0)), 
			 legend=nothing,
			 xlim=xlim,
			 ylim=ylim)

	end every 50

end


function main()
	
	n_particles = 2 
	n_iter = 10

	particles = initialise_particles(n_particles)

	a = []
	
	for n in 1:n_iter
		for i in eachindex(particles)
			particles[i] = move(particles[i])
			println("$n: p = $i; $(particles[i])")
		end
	end
	
end


# main()
create_gif()
