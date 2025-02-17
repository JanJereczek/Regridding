abstract type AbstractRegridding end

"""
    StructuredRegridding
    StructuredRegridding(source_file, source_dimnames, extrapolation_boundary_conditions,
        varnames, source_gridname, target_gridname)

Struct that contains all necessary information for regridding a field from a source grid
to a target grid. `StructuredRegridding` contains the following fields:
- `source_file`: path to the netCDF file containing the source data
- `source_dimnames`: vector of the names of the dimensions of the source data
- `extrapolation_boundary_conditions`: vector of the boundary conditions for the
    extrapolation of the source data
- `varnames`: vector of the names of the variables to be regridded
- `source_gridname`: name of the source grid
- `target_gridname`: name of the target grid
- `source2target`: projection from the source grid to the target grid
- `target2source`: projection from the target grid to the source grid
- `source_dims`: vector of the dimensions of the source data
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
r = StructuredRegridding(source_file, source_dimnames, extrapolation_boundary_conditions,
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
struct StructuredRegridding <: AbstractRegridding
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

function StructuredRegridding(
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
    
    source2target, target2source, source_dims, vars, attributes = init_regridding(
        source_dimnames,
        source_gridname,
        target_gridname,
        source_file,
        varnames,
        attributes2extract,
        scale_dims_by,
        aggregate_vars,
        aggregate_dims,
    )

    interpolators = [linear_interpolation(Tuple(source_dims), var,
        extrapolation_bc = extrapolation_boundary_conditions) for var in vars]
    return StructuredRegridding(
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

function regrid(r::StructuredRegridding, target_grid)
    coords = r.target2source.(target_grid...)
    targetgrid_on_sourceprojection = [extract_dims(coords, i) for i
        in eachindex(r.source_dimnames)]
    return [itp.(targetgrid_on_sourceprojection...) for itp in r.interpolators]
end

struct NearestNeighbourRegridding <: AbstractRegridding # {N<:Int, T<:AbstractFloat}
    source_grid# ::NTuple{N, Array{T, N}}
    target_grid# ::NTuple{N, Array{T, N}}
    nearest_idx# ::Array{NTuple{N, Int}, N}
end

function NearestNeighbourRegridding(source_grid, target_grid)
    nearest_idx = get_nearest_idx(source_grid, target_grid)
    return NearestNeighbourRegridding(source_grid, target_grid, nearest_idx)
end

function regrid(r::NearestNeighbourRegridding, vars) #where {T, N}
    output = [zeros(T, size(r.target_grid[1])) for _ in vars]
    for k in eachindex(output)
        for I in CartesianIndices(r.target_grid[1])
            output[k][I] = r.vars[k][r.nearest_idx[I]...]
        end
    end
    return output
end

function get_nearest_idx(source_grid, target_grid)
    nearest_idx = [Tuple(zeros(Int, length(target_grid))) for _ in target_grid[1]]
    for II in CartesianIndices(target_grid[1])
        nearest_idx[II] = argmin(
            sum([(source_grid[i] .- target_grid[i][II]) .^ 2 for i in eachindex(source_grid)]))
    end
    return nearest_idx
end

function init_regridding(
    source_dimnames,
    source_gridname,
    target_gridname,
    source_file,
    varnames,
    attributes2extract,
    scale_dims_by,
    aggregate_vars,
    aggregate_dims,
)

    sanitycheck_lon_lat(source_dimnames)
    source2target, target2source = get_projections(source_gridname, target_gridname)
    source_dims, vars = load_data(source_file, source_dimnames, varnames)
    attributes = get_attributes(source_file, varnames, attributes2extract)

    source_dims = scale_dims_by .* source_dims
    if !isnothing(aggregate_vars)
        source_dims = aggregate_dims(source_dims)
        for k in eachindex(vars)
            # println("Aggregating $(varnames[k]) with $(aggregate_vars[k])")
            if aggregate_vars isa Vector
                vars[k] = aggregate_vars[k](vars[k])
            else
                vars[k] = aggregate_vars(vars[k])
            end
        end
    end
    return source2target, target2source, source_dims, vars, attributes  
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