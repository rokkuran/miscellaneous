using Plots
pyplot(leg=false)


function main(N::Integer, freq::Integer; verbose::Bool=false)

    a = Float64[0, 2]
    b = Float64[-2, 0]
    c = Float64[2, 0]

    p = Float64[0, 0]

    # initialise plot
    plot([p[1]], [p[2]], xlim=(-2, 2), ylim=(0, 2), 
        leg=nothing, line=nothing, m=(:purple, 1, stroke(0)))

    ps = Matrix{Float64}(freq, 2)

    ps[1, :] = p

    # j = 2  # freq counter for assigning p to array
        
    @gif for i in 2:N

        r = rand()

        if 0 <= r < (1/3)
            p += (a - p) / 2
        elseif (1/3) <= r < (2/3)
            p += (b - p) / 2
        else
            p += (c - p) / 2
        end


        # ps[j, :] = p
        
        if i % freq == 0
            ps[freq, :] = p
            verbose && println("$i/$N | mod | p = $p")
            println(ps)
            
            plot!(ps[:, 1], ps[:, 2], leg=nothing, line=nothing, m=(:purple, 1, stroke(0)))

            # j = 0
        else
            ps[i % freq, :] = p
        end

        # j += 1

    end every 50  # can't set the freq by variable?
end


main(1000, 50, verbose=true)

