include("intro.jl")

# Init regridding
dimnames = ("lon", "lat")
extrapolation_boundary_conditions = (Periodic(), Flat())
varnames = ("z")
source_file = datadir("BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
r = Regrid(source_file, dimnames, extrapolation_boundary_conditions,
    varnames, source_gridname, target_gridname)

# Regrid
x = range(-3040f3, stop = 3040f3, step = 32f3)
X, Y = ndgrid(x, copy(x))
regridded_vars = r((X, Y))
heatmap(regridded_vars[1])