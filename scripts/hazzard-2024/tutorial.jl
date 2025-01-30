include("../intro.jl")

# Define regridding config
source_dimnames = ("lon", "lat")
target_dimnames = ("x", "y")
varnames = ("z",)
filename = "BCs/Hazzard-Richards-2024/HR24_GHF"
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
extrapolation_boundary_conditions = (Periodic(), Flat())

# Define mean GHF regridding
regrid_μ_ghf = StructuredRegridding(
    datadir("$(filename)_mean.nc"),
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions,
)

# Define stddev GHF regridding
regrid_σ_ghf = StructuredRegridding(
    datadir("$(filename)_std.nc"),
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
target_μ = regrid_μ_ghf(target_grid)[1]
target_σ = regrid_σ_ghf(target_grid)[1]
varnames = ("mu_ghf", "sigma_ghf")
vars = (target_μ, target_σ)

# Visualize regridded data for sanity check
fig = Figure(size = (800, 400))
for j in eachindex(varnames)
    ax = Axis(fig[1, j], aspect = DataAspect())
    hidedecorations!(ax)
    heatmap!(ax, vars[j])
end
# save("assets/hazzard2024.png", fig)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
dim_atts = (x_atts, y_atts)

μ_ghf_atts = Dict("units" => "mW/m^2", "long_name" => "Mean geothermal heat flux")
σ_ghf_atts = Dict("units" => "mW/m^2", "long_name" =>
    "Standard deviation of geothermal heat flux")
var_atts = (μ_ghf_atts, σ_ghf_atts)

fn = datadir("$filename-regridded.nc")
save2nc(fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)