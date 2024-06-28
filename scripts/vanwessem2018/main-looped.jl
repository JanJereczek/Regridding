include("../intro.jl")

filepaths = String[]
for (root, dirs, files) in walkdir(datadir("BCs/VanWessem-2018/3D"))
    for file in files
        if occursin(".nc", file)
            push!(filepaths, joinpath(root, file))
        end
    end
end

varnames = String[]
for filepath in filepaths
    i1 = findlast("/", filepath)[1]+1
    i2 = findfirst("_", filepath)[1]-1
    push!(varnames, lowercase(filepath[i1:i2]))
end
varnames = Tuple(varnames)

# Define regridding config
source_dimnames = ("rlon", "rlat", "time")
target_dimnames = ("xc", "yc", "time")
source_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
extrapolation_boundary_conditions = (Flat(), Flat(), Flat())

aggregate_over_months(X) = cat([mean(X[:, :, i:12:end], dims = 3) for i in 1:12]..., dims = 3)
aggregate_dims((x1, x2, x3)) = return(x1, x2, collect(1:12))

# Regrid
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
t = collect(1:12)
target_dims = (x, y, t)
target_grid = ndgrid(target_dims...)
target_vars = Vector{Array{Float32, 3}}(undef, length(filepaths))
target_atts = Vector{Dict{String, String}}(undef, length(filepaths))
for i in eachindex(filepaths)
    regrid = Regrid(
        filepaths[i],
        source_dimnames,
        target_dimnames,
        source_gridname,
        target_gridname,
        varnames[i:i],
        extrapolation_boundary_conditions;
        scale_dims_by = 1f5,
        aggregate_vars = aggregate_over_months,
        aggregate_dims = aggregate_dims,
        attributes2extract = ("units", "long_name")
    )
    target_vars[i] = regrid(target_grid)[1]
    target_atts[i] = regrid.attributes[1]
end

# heatmap(target_vars[4][:, :, 7])

# Save regridded data
x_atts = Dict("units" => "m", "long_name" => "x-coordinate")
y_atts = Dict("units" => "m", "long_name" => "y-coordinate")
t_atts = Dict("units" => "month", "long_name" => "Month number")
dim_atts = (x_atts, y_atts, t_atts)
fn = datadir("ANT-32KM_RACMO-VW18.nc")
save2nc(fn, target_dimnames, target_dims ./ 1f3, dim_atts, varnames, target_vars, target_atts)