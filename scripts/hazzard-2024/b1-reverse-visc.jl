include("../intro.jl")

# Define regridding config
source_dimnames = ("lon", "lat", "r")
varnames = ("eta",)
file_src = datadir("Hazzard-Richards-2024/src/viscosity/global_log10anom_eta.nc")
file_dst = chop(file_src, tail = length("global_log10anom_eta.nc"))
file_dst *= "viscosity_Hazzard2024.nc"
cp(file_src, file_dst, follow_symlinks = true)

eta = ncread(file_dst, "eta")
lon = ncread(file_dst, "lon")
lat = ncread(file_dst, "lat")
r = ncread(file_dst, "r")

lat_ordered = reverse(lat)
eta_ordered = reverse(eta, dims = 2)

ncwrite(lat_ordered, file_dst, "lat")
ncwrite(eta_ordered, file_dst, "eta")
