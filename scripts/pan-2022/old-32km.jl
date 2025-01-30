include("../intro.jl")

##########################################################################################
######################## StructuredRegridding lithospheric thickness ###################################
##########################################################################################
filepath = datadir("Pan-2022/litho_thickness.nc")
varnames = ["T_litho"]

# Define regridding config
source_dimnames = ("lon", "lat")
target_dimnames = ("xc", "yc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
extrapolation_boundary_conditions = (Periodic(), Flat())

regrid = StructuredRegridding(
    filepath,
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions,
)

# Regridding
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
target_dims = (x, y)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
T_litho_regridded = regrid(target_grid)[1]
heatmap(T_litho_regridded)

##########################################################################################
############################### StructuredRegridding viscosity #########################################
##########################################################################################
filepath = datadir("Pan-2022/viscosity.nc")
varnames = ["eta"]

# Define regridding config
source_dimnames = ("lon", "lat", "r")
target_dimnames = ("xc", "yc", "zc")
extrapolation_boundary_conditions = (Periodic(), Flat(), Flat())

regrid = StructuredRegridding(
    filepath,
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions,
)

# Regridding
depths = collect(100f3:100f3:500f3)
z = maximum(regrid.source_dims[3]) .- depths
target_dims = (x, y, z)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
eta_regridded = regrid(target_grid)[1]
heatmap(eta_regridded[:, :, 1])
#########################################

fn = datadir("Pan-2022/ANT-32KM_Latychev.nc")
isfile(fn) && rm(fn)

dim_atts = [
    Dict("units" => "m", "long_name" => "x-coordinate"),
    Dict("units" => "m", "long_name" => "y-coordinate"),
    Dict("units" => "m", "long_name" => "z-coordinate"),
]
var_atts = [
    Dict("units" => "m", "long_name" => "Lithospheric thickness"),
    Dict("units" => "Pa s", "long_name" => "Log10 mantle viscosity"),
]

ncdims = [[target_dimnames[i], collect(target_dims[i]), dim_atts[i]] for i
    in eachindex(target_dimnames)]
ncdims = reduce(vcat, ncdims)
nccreate(fn, "litho_thickness", ncdims[1:6]..., atts = var_atts[1])
ncwrite(T_litho_regridded, fn, "litho_thickness")
nccreate(fn, "log10_eta", ncdims..., atts = var_atts[2])
ncwrite(eta_regridded, fn, "log10_eta")