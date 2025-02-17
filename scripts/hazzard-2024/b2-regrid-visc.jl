include("../intro.jl")

# Define regridding config
source_dimnames = ("lon", "lat", "r")
target_dimnames = ("xc", "yc", "zc")
varnames = ("eta",)
filename = datadir("Hazzard-Richards-2024/src/viscosity/global_log10anom_eta.nc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
extrapolation_boundary_conditions = (Periodic(), Flat(), Flat())

llon = ncread(filename, "lon")
llat = ncread(filename, "lat")
rr = ncread(filename, "r")

# Define mean GHF regridding
regrid_log10σ = StructuredRegridding(
    filename,
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions,
)

dxx = 10
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
dc = ncread(filename, "depth")
z = 6.371f6 .- (dc .* 1f3)
target_dims = (x, y, dc)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
target_log10σ = regrid(regrid_log10σ, target_grid)
varnames = ("log10_sigma_visc",)
vars = target_log10σ

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)

log10σ_ghf_atts = Dict("units" => "log10 Pa s",
    "long_name" => "log10 standard deviation of viscosity")
var_atts = (log10σ_ghf_atts,)
target_dims = (x, y, z)
fn = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_stddev_viscosity_Hazzard2024.nc")
isfile(fn) && rm(fn)
save2nc(fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)

## Or rather add the field to an existing file: