"""
    extract_dims(coords, dim)

Extract a specific dimension `dim` from a Matrix of coordinate tuples `coords`.
"""
extract_dims(coords, dim) = map(x -> x[dim], coords)

"""
    load_data(filepath, dimnames, varnames)

Load dimensions and variables from a netCDF file found at `filepath`, where they are
respectively referred to as `dimnames` and `varnames`.
"""
function load_data(filepath, dimnames, varnames)
    ds = Dataset(filepath)
    dims = Tuple(ds[dimname][:] for dimname in dimnames)
    if length(dimnames) == 1
        vars = Tuple(ds[varname][:] for varname in varnames)
    elseif length(dimnames) == 2
        vars = Tuple(ds[varname][:, :] for varname in varnames)
    elseif length(dimnames) == 3
        vars = Tuple(ds[varname][:, :, :] for varname in varnames)
    end
    close(ds)
    return dims, vars
end
