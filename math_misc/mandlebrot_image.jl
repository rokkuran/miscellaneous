using Colors
using Plots
using HDF5
using Images
# using ImageView
using FileIO


verbose = false

# image resolution
# width, height = (640, 480)
# width, height = (1080, 720)
width, height = (4096, 2160)

xs = linspace(-2.5, 1, width)
ys = linspace(-1, 1, height)

n_iter = 1000

f(z::Complex, c::Complex) = z^2 + c
modulus(a::Complex) = sqrt(real(a)^2 + imag(a)^2)

n_iters = Int32[]
j = 0
for y in ys
  for x in xs
    c = Complex(x, y)
    z = Complex(0, 0)
    i = 0
    while modulus(z) < 2 && i < n_iter
      z = f(z, c)
      verbose && println("$c | $i: $z")
      i += 1
    end
    push!(n_iters, i)
    j % 10000 == 0 && @printf("%.2f | j = %d\n", j / (width * height), j)
    j += 1
  end
end

function write_iterations(n_iters, n_iter, width, height)
  h5open("mandlebrot.h5", "w") do file
    write(file, "$(width)_$(height)_$(n_iter)", n_iters)
  end
end

function read_iterations(n_iters, n_iter, width, height)
  n_iters = h5open("mandlebrot.h5", "r") do file
    read(file, "$(width)_$(height)_$(n_iter)")
  end
  n_iters
end

write_iterations(n_iters, n_iter, width, height)
# a = read_iterations(n_iters, n_iter, width, height)

# cmap = colormap("RdBu", n_iter)
# cmap = colormap("Purples", n_iter)
# cmap = diverging_palette(360, 360, n_iter, logscale=false, wcolor=RGB(1, 1, 0), dcolor1=RGB(0,0,1), dcolor2=RGB(0,0,1))
# cmap = sequential_palette(0, n_iter, wcolor=RGB(1, 1, 0), dcolor1=RGB(0,0,1), logscale=false)
# cmap = linspace(Color.HSV(0,1,1),Color.HSV(330,1,1),64)  # rainbow
# cmap = linspace(color("red"), color("blue"), n_iter)
# cmap = ColorGradient([RGBA(0, 0, 1, 0.01), RGBA(1, 0, 0, 1), [0, 0.9, 1]])
# cmap = ColorGradient(RGB(0, 0, 1), RGBA(1, 0, 0])

C(g::ColorGradient) = RGB[g[z] for z=linspace(0, 1, n_iter)]
# cmap = cgrad(:inferno, scale=:log)
cmap = cgrad(:viridis)
# cmap = cgrad(:viridis, scale=:log)

img = reshape([cmap[i] for i in n_iters], width, height)'
# imshow(img)

path = "/home/rokkuran/workspace/miscellaneous/math_misc"
save("$path/mandlebrot_$(width)_$(height)_$(n_iter).png", img)
