include("../intro.jl")

# Define regridding config
source_dimnames = ("lon", "lat", "r")
target_dimnames = ("xc", "yc", "zc")
varnames = ("___",)
filename = datadir("Hazzard-Richards-2024/src/viscosity/lab_Hazzard2024.nc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
extrapolation_boundary_conditions = (Periodic(), Flat(), Flat())

# Define mean GHF regridding
rgrd = StructuredRegridding(
    filename,
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions,
)

dxx = 32
grid = "ANT-$(dxx)KM"

if grid == "ANT-10KM"
    x = range(-4075f3, stop = 4075f3, step = 10f3)
elseif grid == "ANT-16KM"
    x = range(-3040f3, stop = 3040f3, step = 16f3)
elseif grid == "ANT-32KM"
    x = range(-3040f3, stop = 3040f3, step = 32f3)
end
@show length(x)
y = copy(x)

# Depth in km for regridding; z in m for saving
z = ncread(filename, "r")
target_dims = (x, y, z)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
vars = regrid(rgrd, target_grid)
varnames = ("___",)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)

var_atts = (Dict("units" => "m", "long_name" =>
    "depth of lithosphere-asthenosphere boundary"),)
target_dims = (x, y, z)
fn = datadir("Hazzard-Richards-2024/dst/LAB/$(grid)_lab_Hazzard2024.nc")
isfile(fn) && rm(fn)
save2nc(fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)

## Or rather add the field to an existing file: