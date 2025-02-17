include("../intro.jl")
T = Float32
dxx = 16
grid = "ANT-$(dxx)KM"
fn = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_stddev_viscosity_Hazzard2024.nc")

x = ncread(fn, "xc")
y = ncread(fn, "yc")
z = ncread(fn, "zc")

sigma = ncread(fn, "log10_sigma_visc")
nx, ny, nz = size(sigma)
sigma_ext = zeros(T, nx, ny, nz+2)
view(sigma_ext, :, :, 2:nz+1) .= sigma

# make sigma decay to 0 over 25 km
z_ext = [z[1] + 25f3 , z..., z[end] - 25f3]


# Save regridded data
target_dims = (x, y, z_ext)
target_dimnames = ("xc", "yc", "zc")
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)
var_atts = (Dict("units" => "log10 Pa s",
    "long_name" => "log10 standard deviation of viscosity"),)

file_out = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_extended_"*
    "stddev_viscosity_Hazzard2024.nc")
isfile(file_out) && rm(file_out)
save2nc(
    file_out,
    target_dimnames,
    target_dims,
    dim_atts,
    ("log10_sigma_visc",),
    (sigma_ext,),
    var_atts,
)
