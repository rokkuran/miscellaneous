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


function cardioid_check(z::Complex)
  p = sqrt((real(z) - 0.25)^2 + imag(z)^2)
  if real(z) < p - 2*p^2 + 0.25  # within main cardioid?
    return true
  elseif (real(z) + 1)^2 + imag(z)^2 < (1/16)  # within period-2 bulb?
    return true
  else
    return false
  end
end


function pixel_iter_array(f, n_iter, pixel_ys, pixel_xs; verbose=false)
  n_iters = Int32[]
  n_pixels = 0
  for y in pixel_ys
    for x in pixel_xs
      c = Complex(x, y)
      z = Complex(0, 0)
      i = 0
      # within cardioid/bulb check
      if cardioid_check(c)
        i = n_iter
      else
        z_prev = nothing
        while modulus(z) < 2 && i < n_iter
          z = f(z, c)
          z == z_prev ? i = n_iter : z_prev = z  # periodicity check
          verbose && println("$c | $i: $z")
          i += 1
        end
      end
      push!(n_iters, i)
      n_pixels % 10000 == 0 && @printf("%.2f | n_pixels = %d\n", n_pixels / (width * height), n_pixels)
      n_pixels += 1
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
# rng_real, rng_imag = zoom_window((-1.7590170270659, 0.01916067191295), 1.1e-12)  # diagonal sauron
# rng_real, rng_imag = zoom_window((-1.15412664822215, 0.30877492767139), 9.5e-12)  # mini and stones
# rng_real, rng_imag = zoom_window((0.452721018749286, 0.39649427698014), 1.1e-13)  # sprial of points | fails


# scaling_factor = 2500
scaling_factor = 3000
width, height = get_dimensions(scaling_factor, rng_real, rng_imag)

pixel_xs = linspace(rng_real..., width)
pixel_ys = linspace(rng_imag..., height)

n_iter = 1000

pixel_iters = pixel_iter_array(f, n_iter, pixel_ys, pixel_xs; verbose=false)

filename = "mandelbrot.h5"
name = "$(width)_$(height)_$(n_iter)"

write_iters(pixel_iters, filename, name)
# pixel_iters = read_iters(filename, name)


# cmap = cgrad(:inferno, scale=:log)
# cmap = cgrad(:viridis)
# cmap = cgrad(:viridis, scale=:log)
cmap = cgrad(:dense, scale=:log)

img = reshape([cmap[i] for i in pixel_iters], width, height)'
# imshow(img)

path = "/home/rokkuran/workspace/miscellaneous/math_misc/output"
save("$path/mandelbrot_$name.png", img)
