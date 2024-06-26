using CairoMakie, Interpolations, NetCDF, Proj

# Step 1
filepath = datadir("BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc")
lon = ncread(filepath, "lon")
lat = ncread(filepath, "lat")
μ_ghf = ncread(filepath, "z")
μ_ghf_itp = linear_interpolation((lon, lat), μ_ghf, extrapolation_bc = (Periodic(), Flat()))

# Step 2
x = range(-3040f3, stop = 3040f3, step = 32f3)
y = copy(x)
X, Y = ndgrid(x, y)

# Step 3
source2target = Proj.Transformation("EPSG:4326", "+proj=stere +lat_0=-90 +lat_ts=-80", always_xy=true)
target2source = inv(source2target)
coords = target2source.(X, Y)
Lon = map(x -> x[1], coords)
Lat = map(x -> x[2], coords)

# Step 4
μ_new = μ_ghf_itp.(Lon, Lat)
fig = heatmap(μ_new)
# save("hazzard2024-verbose.png", fig)