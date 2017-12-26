# Miscellaneous Projects
A place for smaller projects that have no other home.



## Optimisation
- N-dimensional Particle Swarm Optimisation (PSO).
- N-dimensional Bees Algorithm (BA).
- Preliminary work applying PSO to ML model parameter tuning.



## Miscellaneous Mathematics

### Diffusion-limited aggregation
Simple simulation and gif creation code. First pass code, still needs some work to be more efficient.

Example output simulation using 1000 particles, 50k iterations, captured every 50 iterations.
![Diffusion-limited aggregation][dla]

### Sierpinski gasket and chaos game
Sierpinski gasket animation and generation. Extended to other polygons.

Sierpinski gasket animation using chaos game approach.
![Sierpinski gasket][sierpinski_gasket]

### Mandelbrot image generation
Few examples below.
![Mandelbrot Set - base][mb_base]
![Mandelbrot Set - lightning][mb_lightning]
![Mandelbrot Set - spiral][mb_spiral]

### Other
- How to choose best toilet strategy simulation.



## Basic Solar System simulation
Simple simulation of planets, example output below. Needs work.
![planetary motion example][nbody_orbits]



## Anime Recommenders
- Uses [Kitsu][kitsu] API to retrieve user/item data.
- Data stored locally in mongodb.
- Preliminary work on content based recommender.
- Preliminary work on SVD based collaborative filtering recommender.



[kitsu]: kitsu.io

[dla]: https://github.com/rokkuran/miscellaneous/blob/master/math_misc/output/dla_1000_50000_-100_100.gif "Diffusion-limited aggregation."

[sierpinski_gasket]: https://github.com/rokkuran/miscellaneous/blob/master/math_misc/output/sierpinksi_gasket.gif "Sierpinski Gasket."

[mb_base]: https://github.com/rokkuran/miscellaneous/blob/master/math_misc/output/mandelbrot_750_500_100000_tmp.png "Mandelbrot Set."

[mb_lightning]: https://github.com/rokkuran/miscellaneous/blob/master/math_misc/output/mandelbrot_3000_3000_2000_lightning.png "Mandelbrot Image 'lightning'."

[mb_spiral]: https://github.com/rokkuran/miscellaneous/blob/master/math_misc/output/mandelbrot_3000_3000_2000_spiral1.png "Mandelbrot Image: 'spiral'."

[nbody_orbits]: https://github.com/rokkuran/miscellaneous/blob/master/nbody/output/orbits3.png "n-body example."
