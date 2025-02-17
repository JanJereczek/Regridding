T = Float32
fn = datadir("ANT-16KM_stdvisc_Hazzard2024_ext.nc")

x = ncread(fn, "xc")
y = ncread(fn, "yc")
z = ncread(fn, "zc")
depth = 6371f3 .- z
sigma = ncread(fn, "log10_sigma_visc")
itp = linear_interpolation((x, y, depth), sigma, extrapolation_bc=(Flat(), Flat(), Flat()))

target_fn = "/home/jan/pCloudSync/PhD/Projects/Isostasy/fastiso-ssp2500/"*
    "data/preprocessed/ANT-16KM_Lloyd2024.nc"
xc = ncread(target_fn, "xc")
yc = ncread(target_fn, "yc")
zc = ncread(target_fn, "zc")
dc = 6371f3 .- zc

X, Y, D = ndgrid(xc, yc, dc)
sigma_out = itp.(X, Y, D)

target_dims = (xc, yc, zc)
varnames = ("log10_sigma_visc",)
vars = (sigma_out,)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)
var_atts = (Dict("units" => "log10 Pa s", "long_name" => "log10 standard deviation of viscosity"),)
save2nc(target_fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)