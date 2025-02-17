include("../intro.jl")
T = Float32
fn = datadir("Hazzard-Richards-2024/src/LAB/$(grid)_Lloyd2024.nc")

x = ncread(fn, "xc")
y = ncread(fn, "yc")
litho_thickness = ncread(fn, "litho_thickness")

target_fn = datadir("Hazzard-Richards-2024/dst/viscosity/$(grid)_viscosity_Hazzard2024.nc")
target_dims = (x, y)
target_dimnames = ("xc", "yc")
varnames = ("litho_thickness",)
vars = (litho_thickness,)

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
dim_atts = (x_atts, y_atts)
var_atts = (Dict("units" => "m", "long_name" => "lithospheric thickness"),)
save2nc(target_fn, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)