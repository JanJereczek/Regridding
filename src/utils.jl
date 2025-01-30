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
    dims = [ncread(filepath, dimname) for dimname in dimnames]
    vars = [dropped_ncread(filepath, varname) for varname in varnames]
    return dims, vars
end

function dropped_ncread(filepath, varname)
    var = ncread(filepath, varname)
    dimnumbers = collect(1:length(size(var)))

    if 1 ∈ size(var)
        return dropdims(var, dims = Tuple(dimnumbers[i] for i in eachindex(dimnumbers)
            if size(var, i) == 1))
    else
        return var
    end
end

function get_attributes(source_file, varnames, attributes2extract)
    if isnothing(attributes2extract)
        return [Dict() for varname in varnames]
    else
        return [Dict(att => ncgetatt(source_file, varname, att) for
            att in attributes2extract) for varname in varnames]
    end
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
    ncdims = reduce(vcat, ncdims)

    for i in eachindex(varnames)
        @show filename, varnames[i], var_atts[i]
        nccreate(filename, varnames[i], ncdims..., atts = var_atts[i])
        ncwrite(vars[i], filename, varnames[i])
    end
end



function recursive_walkdir(dir)
    filepaths = String[]
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if occursin(".nc", file)
                push!(filepaths, joinpath(root, file))
            end
        end
    end
    return filepaths
end

function get_paths_varnames(path::String)
    filepaths = recursive_walkdir(path)
    varnames = String[]
    for filepath in filepaths
        i1 = findlast("/", filepath)[1]+1
        i2 = findfirst("_", filepath)[1]-1
        push!(varnames, lowercase(filepath[i1:i2]))
    end
    return filepaths, varnames
end

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