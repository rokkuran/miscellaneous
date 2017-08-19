using Distributions
using Plots
pyplot()


mutable struct Particle
    x::Vector{Float64}  # position
    b::Vector{Float64}  # best known position
    v::Vector{Float64}  # velocity
end
Particle(x, v) = Particle(x, x, v)


function create_particle(f::Function, search_space::AbstractArray)
    x, v = [], []
    for bound in search_space
        b_low, b_high = bound
        push!(x, rand(Uniform(bound...)))
        push!(v, rand(Uniform(-abs(b_high - b_low), abs(b_high - b_low))))
    end
    Particle(x, v)
end


function status(msg::String, i::Int64, j::Int64, from::AbstractArray,
    to::AbstractArray, f_to::Float64)
    println("$i: $j $msg | $from -> $to [f = $f_to]")
end


function pso(f::Function, swarm_size::Int64, bounds::AbstractArray,
    n_iter::Int64=50, ω::Float64=0.75, ϕp::Float64=0.02, ϕg::Float64=0.1,
    verbose::Bool=false)

    verbose && println("running particle swarm optimisation...\n\n")
    verbose && println("swarm_size = $swarm_size\nn_iter = $n_iter\nω=$ω\nϕp = $ϕp\nϕg = $ϕg\n")

    particles = [create_particle(f, bounds) for _ in 1:swarm_size]

    #TODO: there must be a more elegant way to acheive this??
    g = particles[1].b
    for (i, P) in enumerate(particles[2:end])
        if f(P.b...) < f(g...)
            g = P.b
        end
    end

    i = 0
    while i < n_iter
        for (j, P) in enumerate(particles)
            rp, rg = rand(Uniform(0, 1), 2)
            P.v = ω * P.v + (ϕp * rp * (P.b - P.x)) + (ϕg * rg * (g - P.x))
            P.x += P.v

            if f(P.x...) < f(P.b...)
                verbose && status("best position update", i, j, P.b, P.x, f(P.b...))
                P.b = P.x
                if f(P.b...) < f(g...)
                    verbose && status("new global best", i, j, g, P.x, f(P.b...))
                    g = P.b
                end
            end
        end
        i += 1
    end
    return g
end


function test_function(f::Function, bounds::AbstractArray)
    swarm_size = 200
    n_iter = 100
    ω = 0.75
    ϕp = 0.02
    ϕg = 0.1
    pso(f, swarm_size, bounds, n_iter, ω, ϕp, ϕg, false)
end


function repeated_accuracy(f::Function, search_space::AbstractArray,
    minimum_location::AbstractArray, n::Int64)
    results = []
    for i in 1:n
        a = minimum_location .- test_function(f, search_space)
        push!(results, a)
    end
    results
end


gaussian(x::Float64) = -exp(-(x - 1)^2) + 1  # min @ x=1

function rosenbrock(x::T, y::T) where T <: Float64
    (1 - x)^2 + 100(y - x^2)^2   # min @ (x, y)=(1, 1)
end

function matyas(x::T, y::T) where T <: Float64
    0.26 * (x^2 + y^2) - 0.48x * y  # min @ (x, y)=(0, 0)
end

function polynomial(x::T, y::T, z::T; a=1, b=2, c=3) where T <: Float64
    (x - a)^2 + (y - b)^2 + (z - c)^2  # minimum @ (a, b, c)
end

function rastrigin(x::T, y::T) where T <: Float64
    x^2 + y^2 - cos(18x) - cos(18y) + 2  # min @ (0, 0)
end


function test_all_functions()
    search_space = Array[[-5, 5]]
    result = test_function(gaussian, search_space)
    println("\nmin @ 1 [gaussian] | result=$result")

    search_space = Array[[-1, 1.5], [-2, 3]]
    result = test_function(rosenbrock, search_space)
    println("\nmin @ (1, 1) [rosenbrock] | result=$result")

    search_space = Array[[-5, 5], [-5, 5]]
    result = test_function(matyas, search_space)
    println("\nmin @ (0, 0) [matyas] result=$result")

    search_space = Array[[-5, 7], [-2, 14], [-9, 10]]
    result = test_function(polynomial, search_space)
    println("\nmin @ (1, 2, 3) [polynomial] result=$result")

    search_space = Array[[-1, 1], [-1, 1]]
    result = test_function(rastrigin, search_space)
    println("\nmin @ (0, 0) [rastrigin] result=$result")
end


function test_convergence()
    search_space = Array[[-1, 1], [-1, 1]]
    minimum_location = [0, 0]
    z = repeated_accuracy(rastrigin, search_space, minimum_location, 100)
    println(z)
    histogram(map(x -> norm(x), z))
end


test_all_functions()
# test_convergence()
