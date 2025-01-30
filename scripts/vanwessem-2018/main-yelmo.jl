include("../intro.jl")

filepaths = recursive_walkdir(datadir("VanWessem-2022/3D"))
varnames = String[]
for filepath in filepaths
    i1 = findlast("/", filepath)[1]+1
    i2 = findfirst("_", filepath)[1]-1
    push!(varnames, lowercase(filepath[i1:i2]))
end


# Define regridding config
source_dimnames = ("Lon", "Lat", "time")
target_dimnames = ("Lon", "Lat", "time")
source_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
extrapolation_boundary_conditions = (Flat(), Flat(), Flat())

daysinmonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
averageday_in_month(X) = cat([mean(X[:, :, i:12:end], dims = 3) ./ daysinmonth[i] for
    i in 1:12]..., dims = 3)
average_in_month(X) = cat([mean(X[:, :, i:12:end], dims = 3) for i in 1:12]..., dims = 3)
aggregate_per_day = ["precip", "refreeze", "runoff", "smb", "snowfall", "snowmelt", "subl"]
aggregate_over_month = [ varname in aggregate_per_day ? averageday_in_month :
    average_in_month for varname in varnames]
twelve((x1, x2, x3)) = return(x1, x2, collect(1:12))

# Regridding
dx = 16
x = range(-3040f3, stop = 3040f3, step = dx * 1f3)
y = copy(x)
t = collect(1:12)
target_dims = (x, y, t)
target_grid = ndgrid(target_dims...)
target_vars = Vector{Array{Float32, 3}}(undef, length(filepaths))
target_atts = Vector{Dict{String, String}}(undef, length(filepaths))
for i in eachindex(filepaths)
    regridding = StructuredRegridding(
        filepaths[i],
        source_dimnames,
        target_dimnames,
        source_gridname,
        target_gridname,
        varnames[i:i],
        extrapolation_boundary_conditions;
        scale_dims_by = [1f5, 1f5, 1],
        aggregate_vars = aggregate_over_month[i],
        aggregate_dims = twelve,
        attributes2extract = ("units", "long_name")
    )
    target_vars[i] = regrid(regridding, target_grid)[1]
    target_atts[i] = regridding.attributes[1]
end

alias_units = Dict("kg m-2" => "kg m-2 d-1")
alias_varnames = Dict(
    "precip" => "pr",
    "runoff" => "ru",
    "snowfall" => "sf",
    "subl" => "su",
    "t2m" => "T_srf",
)

function vec_with_alias!(varnames, aliases)
    for k in eachindex(varnames)
        if varnames[k] in keys(aliases)
            varnames[k] = aliases[varnames[k]]
        end
    end
end
function dict_with_alias!(dicts, aliases, keyname)
    for dict in dicts
        if dict[keyname] in keys(aliases)
            dict[keyname] = aliases[dict[keyname]]
        end
    end
end
vec_with_alias!(varnames, alias_varnames)
dict_with_alias!(target_atts, alias_units, "units")

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
t_atts = Dict("units" => "month", "long_name" => "month")
dim_atts = (x_atts, y_atts, t_atts)
fn = datadir("VanWessem-2018/ANT-$(dx)KM_RACMO-VW18.nc")
isfile(fn) && rm(fn)

target_dims = (x ./ 1f3, y ./ 1f3, collect(1.5:1:12.5))
save2nc(fn, target_dimnames, target_dims, dim_atts, varnames,
    target_vars, target_atts)



#########################################



filepaths2D = recursive_walkdir(datadir("VanWessem-2018/2D"))
varnames2D = String[]
for filepath in filepaths2D
    i1 = findlast("/", filepath)[1]+1
    i2 = findfirst("_", filepath)[1]-1
    push!(varnames2D, lowercase(filepath[i1:i2]))
end
source_dimnames = ("rlon", "rlat")
target_dimnames = ("xc", "yc")
target_dims = (x, y)
target_grid = ndgrid(target_dims...)
target_vars = Vector{Array{Float32, 2}}(undef, length(filepaths2D))
target_atts = Vector{Dict{String, String}}(undef, length(filepaths2D))
extrapolation_boundary_conditions = (Flat(), Flat())

regrid2D = StructuredRegridding(
    filepaths2D[1],
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames2D,
    extrapolation_boundary_conditions;
    scale_dims_by = [1f5, 1f5],
    attributes2extract = ("units", "long_name"),
)
target_vars2D = regrid(regrid2D, target_grid)
target_atts2D = regrid2D.attributes
dim_atts2D = (x_atts, y_atts)
alias_varnames = Dict("height" => "zs")
vec_with_alias!(varnames2D, alias_varnames)

save2nc(fn, target_dimnames, target_dims, (x_atts, y_atts), varnames2D,
    target_vars2D, target_atts2D)