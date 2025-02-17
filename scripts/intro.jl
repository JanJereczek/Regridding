using DrWatson
@quickactivate "Regridding"

using CairoMakie
using Dates
using Interpolations
using LazyGrids
using NetCDF
using Unitful
using Proj

# Here you may include files from the source directory
include(srcdir("sanity.jl"))
include(srcdir("utils.jl"))
include(srcdir("regrid.jl"))

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())
"""
)