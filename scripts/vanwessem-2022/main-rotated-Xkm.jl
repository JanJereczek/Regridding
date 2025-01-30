include("../intro.jl")

T = Float32
filepaths3D, varnames3D = get_paths_varnames(datadir("VanWessem-2022/3D"))
filepaths2D, varnames2D = get_paths_varnames(datadir("VanWessem-2022/2D"))

# Original grid
fn = datadir("VanWessem-2022/ANT-32KM-scaled.nc")
dx = 32
x = range(-3040f3, stop = 3040f3, step = dx * 1f3)
y = copy(x)
t = collect(1.5:1:12.5)

# Target grid
dxx = 16
xx = range(-3040f3, stop = 3040f3, step = dxx * 1f3)
yy = copy(xx)

ncdims = [["xc", x, Dict("units" => "m", "long_name" => "x-coordinate")],
    ["yc", y, Dict("units" => "m", "long_name" => "y-coordinate")],
    ["time", t, Dict("units" => "month", "long_name" => "time")]]
ncdims = reduce(vcat, ncdims)
var_atts = get_attributes(fn, varnames3D, ("units", "long_name"))

target_vars = [zeros(T, length(xx), length(yy), length(t)) for _ in varnames3D]
for i in eachindex(varnames3D)
    @show varnames3D[i]
    itp = linear_interpolation((x, y, t), ncread(fn, varnames3D[i]))
    target_vars[i] .= itp(xx, yy, t)
end

alias_varnames = Dict(
    "precip" => "pr",
    "runoff" => "ru",
    "snowfall" => "sf",
    "subl" => "sub",
    "t2m" => "T_srf",
)
vec_with_alias!(varnames3D, alias_varnames)
alias_units = Dict("kg m-2" => "kg m-2 d-1")
dict_with_alias!(var_atts, alias_units, "units")

fndxx = datadir("VanWessem-2022/ANT-$(dxx)KM_RACMO-VW22.nc")
isfile(fndxx) && rm(fndxx)
target_dimnames = ("xc", "yc", "time")
target_dims = (xx ./ 1f3, yy ./ 1f3, t)
target_atts = var_atts
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
t_atts = Dict("units" => "month", "long_name" => "month")
dim_atts = (x_atts, y_atts, t_atts)
save2nc(fndxx, target_dimnames, target_dims, dim_atts, varnames3D, target_vars, target_atts)

target_vars2D = [zeros(T, length(xx), length(yy)) for _ in varnames2D]
for i in eachindex(varnames2D)
    @show varnames2D[i]
    itp = linear_interpolation((x, y), ncread(fn, varnames2D[i]))
    target_vars2D[i] .= itp(xx, yy)
end
target_atts2D = get_attributes(fn, varnames2D, ("units", "long_name"))
alias_varnames = Dict("height" => "zs")
vec_with_alias!(varnames2D, alias_varnames)
save2nc(fndxx, target_dimnames[1:2], target_dims[1:2], (x_atts, y_atts), varnames2D,
    target_vars2D, target_atts2D)