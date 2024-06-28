"""
    Regrid
    Regrid(source_file, source_dimnames, extrapolation_boundary_conditions,
        varnames, source_gridname, target_gridname)

Struct that contains all necessary information for regridding a field from a source grid
to a target grid. `Regrid` contains the following fields:
- `source_file`: path to the netCDF file containing the source data
- `source_dimnames`: tuple of the names of the dimensions of the source data
- `extrapolation_boundary_conditions`: tuple of the boundary conditions for the
    extrapolation of the source data
- `varnames`: vector of the names of the variables to be regridded
- `source_gridname`: name of the source grid
- `target_gridname`: name of the target grid
- `source2target`: projection from the source grid to the target grid
- `target2source`: projection from the target grid to the source grid
- `source_dims`: tuple of the dimensions of the source data
- `vars`: vector of the variables to be regridded
- `interpolators`: vector of the interpolators for the variables to be regridded

# Examples

```julia
source_dimnames = ("lon", "lat")
extrapolation_boundary_conditions = (Periodic(), Flat())
varnames = ("z")
source_file = datadir("BCs/Hazzard-Richards-2024/HR24_GHF_mean.nc")
source_gridname = "EPSG:4326"
target_gridname = "+proj=stere +lat_0=-90 +lat_ts=-80"
r = Regrid(source_file, source_dimnames, extrapolation_boundary_conditions,
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
    source_dimnames#::NTuple{N, String}
    target_dimnames#::NTuple{N, String}
    source_gridname::String
    target_gridname::String
    source2target::Proj.Transformation
    target2source::Proj.Transformation
    source_dims
    varnames#::Vector{String}
    vars
    extrapolation_boundary_conditions#::NTuple{N, <:Interpolations.BoundaryCondition}
    interpolators
    attributes
end

function Regrid(
    source_file,
    source_dimnames,
    target_dimnames,
    source_gridname,
    target_gridname,
    varnames,
    extrapolation_boundary_conditions;
    scale_dims_by = 1,
    aggregate_vars = nothing,
    aggregate_dims = nothing,
    attributes2extract = nothing,
)
    sanitycheck_lon_lat(source_dimnames)
    source2target, target2source = get_projections(source_gridname, target_gridname)
    source_dims, vars = load_data(source_file, source_dimnames, varnames)
    attributes = get_attributes(source_file, varnames, attributes2extract)

    source_dims = scale_dims_by .* source_dims
    if !isnothing(aggregate_vars)
        vars = aggregate_vars.(vars)
        source_dims = aggregate_dims(source_dims)
    end
    
    interpolators = [linear_interpolation(source_dims, var,
        extrapolation_bc = extrapolation_boundary_conditions) for var in vars]
    return Regrid(
        source_file,
        source_dimnames,
        target_dimnames,
        source_gridname,
        target_gridname,
        source2target,
        target2source,
        source_dims,
        varnames,
        vars,
        extrapolation_boundary_conditions,
        interpolators,
        attributes,
    )
end

function (r::Regrid)(target_grid)
    coords = r.target2source.(target_grid...)
    targetgrid_on_sourceprojection = Tuple(extract_dims(coords, i) for i
        in eachindex(r.source_dimnames))
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