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

"""
    missings2nans(X::Array{Union{T, Missing}})

Replace missing values in `X` with NaNs and convert to an `Array{T}`.
"""
function missings2nans(X::Array{Union{T, Missing}}) where T
    X[ismissing.(X)] .= NaN32
    return convert(Array{T}, X)
end

"""
    save2nc(filename, target_dimnames, target_dims, dim_atts, varnames, vars, var_atts)

Save `dims` and `vars` to a netCDF file found at `filename`. The dimensions are
referred to as `target_dimnames`and the variables are referred to as `varnames`.
The attributes of the dimensions are given by `dim_atts`, and the attributes of
the variables are given by `var_atts`.
"""
function save2nc(
    filename,
    target_dimnames,
    target_dims,
    dim_atts,
    varnames,
    vars,
    var_atts,
)
    ncdims = [[target_dimnames[i], collect(target_dims[i]), dim_atts[i]] for i
        in eachindex(target_dimnames)]
    ncdims = Tuple(reduce(vcat, ncdims))

    for i in eachindex(varnames)
        nccreate(filename, varnames[i], ncdims...,
            atts = var_atts[i])
        ncwrite(vars[i], filename, varnames[i])
    end
end