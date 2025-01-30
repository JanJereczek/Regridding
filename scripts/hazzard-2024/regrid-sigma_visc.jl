include("../intro.jl")

# Define regridding config
source_dimnames = ("lon", "lat", "depth")
target_dimnames = ("xc", "yc", "zc")
varnames = ("log10_sigma",)
filename = "/home/jan/pCloudSync/PhD/Projects/Isostasy/fastiso-ssp2500/data/preprocessed/viscosity_uncertainty.nc"
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
extrapolation_boundary_conditions = (Periodic(), Flat(), Flat())

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

grid = "ANT-10KM"
if grid == "ANT-10KM"
    x = range(-4075f3, stop = 4075f3, step = 10f3)
elseif grid == "ANT-16KM"
    x = range(-3040f3, stop = 3040f3, step = 16f3)
elseif grid == "ANT-32KM"
    x = range(-3040f3, stop = 3040f3, step = 32f3)
end
@show length(x)
y = copy(x)

# Regridding
z = 6.371f6 .- collect(75f3:25f3:400f3)
zn = collect(75:25:400)
target_dims = (x, y, zn)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
target_log10σ = regrid_log10σ(target_grid)[1]
varnames = ("log10_sigma_visc",)
vars = (target_log10σ,)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)

log10σ_ghf_atts = Dict("units" => "log10 Pa s", "long_name" => "log10 standard deviation of viscosity")
var_atts = (log10σ_ghf_atts,)

target_dims = (x, y, z)
fn = datadir("$(grid)_stdvisc_Hazzard2024.nc")
save2nc(fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)