"""
    Regrid
    Regrid(source_file, dimnames, extrapolation_boundary_conditions,
        varnames, source_gridname, target_gridname)

Struct that contains all necessary information for regridding a field from a source grid
to a target grid. `Regrid` contains the following fields:
- `source_file`: path to the netCDF file containing the source data
- `dimnames`: tuple of the names of the dimensions of the source data
- `extrapolation_boundary_conditions`: tuple of the boundary conditions for the
    extrapolation of the source data
- `varnames`: vector of the names of the variables to be regridded
- `source_gridname`: name of the source grid
- `target_gridname`: name of the target grid
- `source2target`: projection from the source grid to the target grid
- `target2source`: projection from the target grid to the source grid
- `dims`: tuple of the dimensions of the source data
- `vars`: vector of the variables to be regridded
- `interpolators`: vector of the interpolators for the variables to be regridded

# Examples

```julia
dimnames = ("lon", "lat")
extrapolation_boundary_conditions = (Periodic(), Flat())
varnames = ("z")
source_file = datadir("BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
r = Regrid(source_file, dimnames, extrapolation_boundary_conditions,
    varnames, source_gridname, target_gridname)
```
___________________________________________________________________________________________

The regridding is done by calling the struct with the target grid as
argument.

# Examples

```julia
x = range(-3040f3, stop = 3040f3, step = 32f3)
X, Y = ndgrid(x, copy(x))
regridded_vars = r((X, Y))
```
"""
struct Regrid
    source_file::String
    dimnames#::NTuple{N, String}
    extrapolation_boundary_conditions#::NTuple{N, <:Interpolations.BoundaryCondition}
    varnames::Vector{String}
    source_gridname::String
    target_gridname::String
    source2target::Proj.Transformation
    target2source::Proj.Transformation
    dims
    vars
    interpolators
end

function Regrid(
    source_file,
    dimnames,
    extrapolation_boundary_conditions,
    varnames,
    source_gridname,
    target_gridname,
)
    sanitycheck_lon_lat(dimnames)
    source2target, target2source = get_projections(source_gridname, target_gridname)
    dims, vars = load_data(source_file, dimnames, varnames)
    interpolators = [linear_interpolation(dims, var,
        extrapolation_bc = extrapolation_boundary_conditions) for var in vars]
    return Regrid(
        source_file,
        dimnames,
        extrapolation_boundary_conditions,
        varnames,
        source_gridname,
        target_gridname,
        source2target,
        target2source,
        dims,
        vars,
        interpolators,
    )
end

function (r::Regrid)(target_grid)
    coords = r.target2source.(target_grid...)
    targetgrid_on_sourceprojection = Tuple(extract_dims(coords, i) for i
        in eachindex(r.dimnames))
    return Tuple(itp.(targetgrid_on_sourceprojection...) for itp in r.interpolators)
end

"""
    get_projections(source_gridname, target_gridname)

Get the projections from the source grid to the target grid and vice versa.
"""
function get_projections(source_gridname, target_gridname)
    source2target = Proj.Transformation(source_gridname, target_gridname, always_xy=true)
    target2source = inv(source2target)
    return source2target, target2source
end

"""
    save2nc(file, varname, var, dimsnames, dims)

Save a field to a netCDF file.
"""
function save2nc(file, varname, var, dimsnames, dims)
    ds = NCDataset(file, "c")
    for (name, dim) in zip(dimsnames, dims)
        println("$name, $dim")
        defDim(ds, name, length(dim))
        defVar(ds, name, dim, (name,))
        ds[name][:] = dim
    end
    defVar(ds, varname, var, dimsnames)
    close(ds)
end


"""
    regrid(file, var, dimsnames, newdims)

Regrid a field from a netCDF file to a new grid.
"""
function regrid(file, var, dimsnames, newdims)
    ds = NCDataset(file, "r")
    dims = Tuple(ds[d][:] for d in dimsnames)
    grid = ndgrid(newdims...)
    field = readnc(ds, var, dimsnames)
    close(ds)
    itp = linear_interpolation(dims, field)
    return itp.(grid...)
end
