include("../intro.jl")
dxx = 16
grid = "ANT-$(dxx)KM"
file_src = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_viscosity_Hazzard2024.nc")
file_dst = datadir("Hazzard-Richards-2024/dst/$(grid)_Hazzard2024.nc")
cp(file_src, file_dst, force=true)

source_dimnames = ("xc", "yc", "zc")
target_dimnames = ("xc", "yc", "zc")
x = ncread(file_dst, "xc")
y = ncread(file_dst, "yc")
z = ncread(file_dst, "zc")
target_dims = (x, y, z)

x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
z_atts = Dict("units" => "m", "long_name" => "z-coordinate")
dim_atts = (x_atts, y_atts, z_atts)

stddev_viscosity_atts = Dict("units" => "log10 Pa s", "long_name" =>
    "log10 standard deviation of viscosity")
lab_depth_atts = Dict("units" => "m", "long_name" =>
    "depth of lithosphere-asthenosphere boundary")

stddev_visc_file = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)"*
    "_stddev_viscosity_Hazzard2024.nc")
lab_file = datadir("Hazzard-Richards-2024/dst/LAB/$(grid)_lab_Hazzard2024.nc")
stddev_viscosity = ncread(stddev_visc_file, "log10_sigma_visc")
# lab_depth = ncread(lab_file, "litho_thickness")

vars = (stddev_viscosity,) #, lab_depth)
varnames = ("stddev_log10_visc",) #, "litho_thickness")
var_atts = (stddev_viscosity_atts,) #, lab_depth_atts)

save2nc(file_dst, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)
