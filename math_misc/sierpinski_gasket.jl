using Plots
pyplot(leg=false)



mutable struct State
    vertices::AbstractArray
    p::AbstractArray
end


function update!(s::State; verbose::Bool=false)
    # chaos game approach to create Sierpiński gasket

    r = rand()
    n = length(s.vertices)

    verbose && println("n = $n; r = $r")

    lb, ub = 0, 1/n
    for i in 1:n
        verbose && println("$i: [$lb, $ub)")
        if lb <= r < ub
            verbose && println("\tbetween bounds: $i")
            s.p += (s.vertices[i] - s.p) / 2
        end
        lb, ub = ub, (i+1)/n
    end
    s
end


function bounds(s::State)

    b = []
    for d in eachindex(s.vertices[1])
        push!(b, [s.vertices[1][d], s.vertices[1][d]])
    end

    for (i, v) in enumerate(s.vertices)
        if i > 1
            for d in eachindex(v)
                if v[d] < b[d][1]
                    b[d][1] = v[d]  # minimum
                elseif v[1] > b[d][2]
                    b[d][2] = v[d]  # maximum
                end
            end
        end
    end

    b
end


function create_animation(state::State, N::Integer, freq::Integer; verbose::Bool=false)

    # initialise plot
    xlim, ylim = bounds(state)

    plot(
        [state.p[1]], [state.p[2]], 
        xlim=xlim, ylim=ylim, 
        m=(:purple, 1, stroke(0)), 
        line=nothing, leg=nothing
    )

    ps = Matrix{Float64}(freq, 2)
    ps[1, :] = state.p
    
    @gif for i in 2:N

        update!(state)

        if i % freq == 0
            ps[freq, :] = state.p
            plot!(ps[:, 1], ps[:, 2], leg=nothing, line=nothing, m=(:purple, 1, stroke(0)))

            verbose && println("$i/$N | mod | p = $(state.p)")
        else
            ps[i % freq, :] = state.p
        end

    end every 5000  # can't set the freq by variable?
end


function main()

    # # sierpinski gasket
    # state = State(
    #     [[0, 2], [-2, 0], [2, 0]],  # equalateral triangle
    #     [0, 0]  # initial value
    # )

    state = State(
        [[0, 5], [-2, 0], [2, 0], [0, -3]],  # kite quadralateral
        [0, 0]  # initial value
    )
    # TODO: work out how to set freq as variable when using every from @gif macro
    create_animation(state, 70000, 5000, verbose=true)

end


main()