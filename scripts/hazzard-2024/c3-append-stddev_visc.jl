include("../intro.jl")
T = Float32
fn = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_extended_"*
    "stddev_viscosity_Hazzard2024.nc")

x = ncread(fn, "xc")
y = ncread(fn, "yc")
z = reverse(ncread(fn, "zc"))
sigma = reverse(ncread(fn, "log10_sigma_visc"), dims=3)
itp = linear_interpolation((x, y, z), sigma, extrapolation_bc=(Flat(), Flat(), Flat()))

target_fn = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_viscosity_Hazzard2024.nc")
xc = ncread(target_fn, "xc")
yc = ncread(target_fn, "yc")
zc = ncread(target_fn, "zc")
sigma_out = itp.(ndgrid(xc, yc, zc)...)
target_dims = (xc, yc, zc)
varnames = ("stddev_log10_visc",)
vars = (sigma_out,)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)
var_atts = (Dict("units" => "log10 Pa s", "long_name" => "std. deviation of log10 viscosity"),)
save2nc(target_fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)