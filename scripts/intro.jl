using DrWatson
@quickactivate "Regridding"

using CairoMakie
using GeoStats
using Interpolations
using LazyGrids
using NCDatasets
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