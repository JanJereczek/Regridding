# Regridding

## Getting started

This project is authored by Jan Swierczek-Jereczek. To (locally) reproduce it, do the following:

1. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
2. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

You may notice that all scripts start with the command:
```julia
include("intro.jl")
```
which activates the project, imports important packages and enables local path handling from DrWatson.

## Introduction

This repository aims to centralise the julia regridding routines used within the palma-ice group. The internal workflow can be summarized as:

1. Load the source data on the source grid by using `NCDatasets` and define an interpolator by using `Interpolations.jl`. We here require the user to have preprocessed their data into a NetCDF file.
1. Define the target grid. For this we use `LazyGrids.jl`, which is memory-efficient and simple to use.
2. Compute the associated coordinates on the projection where the source data is defined. For this we use `Proj.jl` which offers a wide range of transformations that can be easily adjusted through keyword arguments.
3. Pass the target grid to the interpolator.

We propose to illustrate this with an example, where the geothermal heat flux data from Hazzard and Richards (2024) is regridded from lon-lat to stereographic:

```julia
using CairoMakie, Interpolations, NCDatasets, Proj

# Step 1
filepath = datadir("BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc")
ds = Dataset(filepath)
lon = ds["lon"][:]
lat = ds["lat"][:]
μ_ghf = ds["z"][:, :]
close(ds)
μ_ghf_itp = linear_interpolation((lon, lat), μ_ghf, extrapolation_bc = (Periodic(), Flat()))

# Step 2
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
X, Y = ndgrid(x, y)

# Step 3
ll2st = Proj.Transformation("EPSG:4326", "+proj=stere +lat_0=-90 +lat_ts=-80", always_xy=true)
st2ll = inv(ll2st)
coords = st2ll.(X, Y)
Lon = map(x -> x[1], coords)
Lat = map(x -> x[2], coords)

# Step 4
μ_new = μ_ghf_itp.(Lon, Lat)
heatmap(μ_new)
```

This code snippet is however somewhat verbose and can be conveniently replaced by the convenience functions implemented in `Regridding.jl`:

```julia
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
X, Y = ndgrid(x, y)

prob = RegriddingProblem(
    source_file = "BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc",
    dims = ["x", "y"],
    vars = ["z"],
    source_gridname = "EPSG:4326",
    target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80",
    target_grid = (X, Y),
)

compute!(prob)
```

That's it! You can then access the results by using the fields defined in `prob` as, for example, `prob.target_data`.

There are other ways to perform this operation and we here want to briefly outline why we chose to use the one outlined above. `Interpolations.jl` is a performant and well-maintained package that offers a user-friendly treatment of the boundary conditions, which is important when we use lon-lat grids. However, `Interpolations.jl` **requires rectangular grids** as source. This is achieved with the workflow above and could not be done so easily if we would project the `(lon, lat)` vectors to `(x, y)`.

## Conventions

In future, we will try to make `Regridding.jl` as general as possible. For now, we however prefer to define some important conventions that prevent such flexibility but ease the initial development:

1. We **always** use `(lon, lat)` ordering.

## Visualization

Visualizing data constitutes the main step of a sanity check. For this, we use `CairoMakie.jl`.

Additionally, `Geostats.jl` is included in this project since it offers a nice interface to filter data, include units, visualize non-equispaced data... etc. However it is not ready yet to perform the regridding task we here focus on (might come in future releases).