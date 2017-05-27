using Colors
using Plots
using HDF5
using Images
# using ImageView
using FileIO


verbose = false


function get_dimensions(α, x::Tuple{Real, Real}, y::Tuple{Real, Real})
  width = x[2] - x[1]
  height = y[2] - y[1]
  r = width / height
  println("$width, $height | $r")
  Int(round(α * r)), Int(round(α))
end


function zoom_window(point::Tuple{Real, Real}, r::Real)
  a, b = point
  rng_real = (a - r, a + r)
  rng_imag = (b - r, b + r)
  return rng_real, rng_imag
end


f(z::Complex, c::Complex) = z^2 + c
modulus(a::Complex) = sqrt(real(a)^2 + imag(a)^2)


function pixel_iter_array(f, n_iter, pixel_ys, pixel_xs; verbose=false)
  n_iters = Int32[]
  j = 0
  for y in pixel_ys
    for x in pixel_xs
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
  n_iters
end


function write_iters(n_iters, filename::String, name::String)
  h5open(filename, "w") do file
    write(file, name, n_iters)
  end
end


function read_iters(filename::String, name::String)
  n_iters = h5open(filename, "r") do file
    read(file, name)
  end
  n_iters
end


# normal range
rng_real = (-2, 1)
rng_imag = (-1, 1)

# point 1
# r = 0.005
# rng_real, rng_imag = zoom_window((-0.7463, 0.1102), r)

# spiral: -0.761574 - 0.0847596i
# r = 6.5e-4
# rng_real, rng_imag = zoom_window((-0.7453, 0.1127), r)

# rng_real, rng_imag = zoom_window((-0.925, 0.266), 0.032)
# rng_real, rng_imag = zoom_window((-0.235125, 0.827215), 8.0e-5)  # lightning
# rng_real, rng_imag = zoom_window((0.2929859127507, 0.6117848324958), 4.4e-11)  # spiral eye thing


scaling_factor = 2500
width, height = get_dimensions(scaling_factor, rng_real, rng_imag)

pixel_xs = linspace(rng_real..., width)
pixel_ys = linspace(rng_imag..., height)

n_iter = 1000

pixel_iters = pixel_iter_array(f, n_iter, pixel_ys, pixel_xs; verbose=false)

filename = "mandlebrot.h5"
name = "$(width)_$(height)_$(n_iter)"

write_iters(pixel_iters, filename, name)
# pixel_iters = read_iters(filename, name)


# cmap = cgrad(:inferno, scale=:log)
cmap = cgrad(:viridis)
# cmap = cgrad(:viridis, scale=:log)
# cmap = cgrad(:dense, scale=:log)

img = reshape([cmap[i] for i in pixel_iters], width, height)'
# imshow(img)

path = "/home/rokkuran/workspace/miscellaneous/math_misc/output"
save("$path/mandlebrot_$name.png", img)
