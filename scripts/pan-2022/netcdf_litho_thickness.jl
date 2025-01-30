using DelimitedFiles

data, _ = readdlm(datadir("Pan-2022/litho_thickness.llz"), header = true)
lon = view(data, :, 1)
lat = view(data, :, 2)
T_litho_vec = view(data, :, 3)
nlon = findfirst(lon .== 360)
nlat = Int( (nlon - 1) / 2 + 1 )
T_litho = collect(reverse(reshape(T_litho_vec, nlon, nlat), dims = 2))
heatmap(T_litho)

# Save regridded data
x_atts = Dict("units" => "degree", "long_name" => "longitude")
y_atts = Dict("units" => "degree", "long_name" => "latitude")
dim_atts = (x_atts, y_atts)
fn = datadir("Pan-2022/litho_thickness.nc")
isfile(fn) && rm(fn)

lon_vec = range(0, stop = 360, length = nlon)
lat_vec = range(-90, stop = 90, length = nlat)
lon_atts = Dict("units" => "degree", "long_name" => "longitude")
lat_atts = Dict("units" => "degree", "long_name" => "latitude")
dim_atts = (lon_atts, lat_atts)
T_litho_atts = Dict("units" => "km", "long_name" => "Lithosphere thickness")
var_atts = (T_litho_atts,)

save2nc(fn, ("lon", "lat"), (lon_vec, lat_vec), dim_atts, ("T_litho",), (T_litho, ), var_atts)
