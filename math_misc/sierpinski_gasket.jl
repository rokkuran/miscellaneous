using Plots
pyplot(leg=false)


function create_animation(N::Integer, freq::Integer; verbose::Bool=false)

    # vertices: equalateral triangle
    a = Float64[0, 2]
    b = Float64[-2, 0]
    c = Float64[2, 0]

    p = Float64[0, 0]  # initial position

    # initialise plot
    plot(
        [p[1]], [p[2]], 
        xlim=(-2, 2), ylim=(0, 2), 
        m=(:purple, 1, stroke(0)), 
        line=nothing, leg=nothing
    )

    ps = Matrix{Float64}(freq, 2)
    ps[1, :] = p
    
    @gif for i in 2:N

        # chaos game approach to create Sierpiński gasket
        r = rand()
        if 0 <= r < (1/3)
            p += (a - p) / 2
        elseif (1/3) <= r < (2/3)
            p += (b - p) / 2
        else
            p += (c - p) / 2
        end

        if i % freq == 0
            ps[freq, :] = p
            plot!(ps[:, 1], ps[:, 2], leg=nothing, line=nothing, m=(:purple, 1, stroke(0)))

            verbose && println("$i/$N | mod | p = $p")
        else
            ps[i % freq, :] = p
        end

    end every 500  # can't set the freq by variable?
end

# TODO: work out how to set freq as variable when using every from @gif macro
create_animation(30000, 500, verbose=true)

