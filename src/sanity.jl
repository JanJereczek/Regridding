"""
    sanitycheck_lon_lat(dimnames)

Check if the dimensions are in the correct order for regridding.
"""
function sanitycheck_lon_lat(dimnames)
    if "lon" ∈ dimnames && "lat" ∈ dimnames
        ilon = findfirst(x -> x == "lon", dimnames)
        ilat = findfirst(x -> x == "lat", dimnames)
        if ilat < ilon
            error("Regridding only accepts (lon, lat) ordering, (lat, lon) not allowed.")
        end
    end
end