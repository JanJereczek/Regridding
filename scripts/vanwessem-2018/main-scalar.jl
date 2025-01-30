include("../intro.jl")

filepaths = String[]
for (root, dirs, files) in walkdir(datadir("BCs/VanWessem-2018"))
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

i = 2
# Define mean GHF regridding
regrid = StructuredRegridding(
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
)

# Regridding
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
t = collect(1:12)
target_dims = (x, y, t)
target_grid = ndgrid(target_dims...)

# Filter out missing values and pack into a tuple.
target_var = regrid(target_grid)[1]
heatmap(target_var[:, :, 2])