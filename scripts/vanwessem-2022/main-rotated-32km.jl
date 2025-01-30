include("../intro.jl")

T = Float32
filepaths3D, varnames3D = get_paths_varnames(datadir("VanWessem-2022/3D"))
filepaths2D, varnames2D = get_paths_varnames(datadir("VanWessem-2022/2D"))

daysinmonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
averageday_in_month(X) = cat([mean(X[:, :, i:12:end], dims = 3) ./ daysinmonth[i] for
    i in 1:12]..., dims = 3)
average_in_month(X) = cat([mean(X[:, :, i:12:end], dims = 3) for i in 1:12]..., dims = 3)
aggregate_per_day = ["precip", "refreeze", "runoff", "smb", "snowfall", "snowmelt", "subl"]
aggregate_over_month = [ varname in aggregate_per_day ? averageday_in_month :
    average_in_month for varname in varnames3D]

dx = 32
x = range(-3040f3, stop = 3040f3, step = dx * 1f3)
y = copy(x)
t = collect(1:12)
n1, n2, n3, n4 = size(ncread(filepaths3D[1], varnames3D[1]))

source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-71"
source2target = Proj.Transformation(source_gridname, target_gridname, always_xy=true)
target2source = inv(source2target)
target_xy_grid = ndgrid(x, y)
coords = target2source.(target_xy_grid...)
Lon = [c[1] for c in coords]
Lat = [c[2] for c in coords]
source_grid = (ncread(filepaths2D[1], "lon"), ncread(filepaths2D[1], "lat"))
target_grid = (Lon, Lat)

regridding = NearestNeighbourRegridding(source_grid, target_grid)
vars3D = [zeros(T, size(Lon)..., size(t)...) for _ in varnames3D]
Y = zeros(T, n1, n2, length(t))
for k in eachindex(varnames3D)
    @show varnames3D[k]
    Y .= aggregate_over_month[k](view(ncread(filepaths3D[k], varnames3D[k]), :, :, 1, :))
    for J in CartesianIndices(Lon)
        vars3D[k][J, :] = Y[regridding.nearest_idx[J]..., :]
    end
end

vars2D = [zeros(T, size(Lon)) for _ in varnames2D]
X = zeros(T, n1, n2)
for k in eachindex(varnames2D)
    @show varnames2D[k]
    X .= ncread(filepaths2D[k], varnames2D[k])
    for J in CartesianIndices(Lon)
        vars2D[k][J] = X[regridding.nearest_idx[J]...]
    end
end

ncdims = [["xc", x, Dict("units" => "m", "long_name" => "x-coordinate")],
    ["yc", y, Dict("units" => "m", "long_name" => "y-coordinate")],
    ["time", collect(1.5:1:12.5), Dict("units" => "month", "long_name" => "time")]]
ncdims = reduce(vcat, ncdims)
fname = datadir("VanWessem-2022/ANT-$(dx)KM-scaled.nc")
isfile(fname) && rm(fname)
for i in eachindex(varnames3D)
    var_atts = get_attributes(filepaths3D[i], varnames3D[i:i], ("units", "long_name"))[1]
    nccreate(fname, varnames3D[i], ncdims..., atts = var_atts)
    ncwrite(vars3D[i], fname, varnames3D[i])
end
for i in eachindex(varnames2D)
    var_atts = get_attributes(filepaths2D[i], varnames2D[i:i], ("units", "long_name"))[1]
    nccreate(fname, varnames2D[i], ncdims[1:6]..., atts = var_atts)
    ncwrite(vars2D[i], fname, varnames2D[i])
end