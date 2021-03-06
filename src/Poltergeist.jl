__precompile__()

module Poltergeist

using Base, ApproxFun, ApproxFunBase, BandedMatrices, Compat, DualNumbers, DomainSets, StaticArrays, LightGraphs#, PyPlot#, FastTransforms
using LinearAlgebra

import Base: values,getindex,setindex!,*,+,-,==,<,<=,>,|,
  >=,/,^,\,∪,∘,transpose, size, length,  eltype, inv, mod, convert#issymmetric,
@compat import LinearAlgebra: eigvals, eigvecs
import ApproxFun: domainspace, rangespace, domain, RaggedMatrix,
  resizedata!, colstop, Infinity,
  fromcanonicalD, tocanonicalD, fromcanonical, tocanonical, space, eigs, cfstype, prectype
import ApproxFunBase: israggedbelow, CachedOperator
import DomainSets: AbstractInterval, UnionDomain

export (..), Interval, PeriodicSegment, Fun, eigs

include("general.jl")
include("maps/maps.jl")
include("HGraphs.jl")
include("hofbauerextension.jl")
include("InducedMap.jl")
include("BackSum.jl")
include("spectral/spectral.jl")
include("timeseries.jl")
include("poetry.jl")

end # module
