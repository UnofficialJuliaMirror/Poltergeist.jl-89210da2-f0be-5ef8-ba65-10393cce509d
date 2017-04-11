# MarkovMaps
export MarkovMap, branch, nbranches, induce, CircleMap

abstract AbstractMarkovMap{D<:Domain,R<:Domain}# <: Function
#abstract AbstractDerivativeMarkovMap{D<:Domain,R<:Domain,T,FF} <: AbstractMarkovMap{D,R,T,FF}

Base.summary(m::AbstractMarkovMap) =  string(typeof(m).name.name)*":"*string(domain(m))*"↦"*string(rangedomain(m)) #branches??
Base.eltype(m::AbstractMarkovMap) = eltype(rangedomain(m))
Base.show(io::IO,m::AbstractMarkovMap) = print(io,typeof(m)) #temporary


immutable MarkovMap{D<:Domain,R<:Domain,B<:MarkovBranch} <: AbstractMarkovMap{D,R}
  branches::AbstractVector{B}
  domain::D
  rangedomain::R
  function MarkovMap(branches,dom,ran)
    domd = Domain(dom); randm = Domain(ran)
    @assert all(b->issubset(b.domain,domd),branches)
    @assert all(b->(b.rangedomain == randm),branches)
    # for i = 1:length(branches)
    #   for j = 1:i-1
    #     ~isempty(branches[i].domain ∩ branches[j].domain) && error("Overlapping domains in branches $i and $j")
    #   end
    # end
    # length(dom) == 1 && arclength(dom)/sum([arclength(b.domain) for b in branches]) < 1-200eps(eltype(dom)) && warn("Warning: possibly missing branches")
    new{typeof(domd),typeof(randm),B}(branches,domd,randm)
  end
end
function MarkovMap{B<:MarkovBranch}(branches::AbstractVector{B},dom,ran)
  domd = Domain(dom); randm = Domain(ran)
  MarkovMap{typeof(domd),typeof(randm),B}(branches,domd,randm)
end

# MarkovMap{T,ff<:Number}(dom::Domain,ran::Domain,f::AbstractVector{ff},dfdx::AbstractVector{ff},bl::AbstractVector{T},bu::AbstractVector{T}) =
#   MarkovMap{T,ff}(dom,ran,f,dfdx,bl,bu)

# function MarkovMap{D<:Domain,R<:Domain}(
#     dom::D,ran::R,v1::AbstractVector,v2::AbstractVector,dir::AbstractString="fwd")
#   MarkovMap(dom,ran,branch(v1,v2,ran,dir))
# end
# function MarkovMap{D<:Domain,R<:Domain}(
#     dom::D,ran::R,v1::AbstractVector,v2::AbstractVector,v3::AbstractVector,dir::AbstractString="fwd")
#   MarkovMap(dom,ran,branch(v1,v2,v3,ran,dir))
# end
# function MarkovMap{D<:Domain,R<:Domain}(
#     dom::D,ran::R,v1::AbstractVector,v2::AbstractVector,v3::AbstractVector,v4::AbstractVector,dir::AbstractString="fwd")
#   MarkovMap(dom,ran,branch(v1,v2,v3,v4,ran,dir))
# end

function MarkovMap(fs::AbstractVector,ds::AbstractVector,ran;dir::AbstractString="fwd")
  @assert length(fs) == length(ds)
  dsm = [Domain(d) for d in ds]
  @compat MarkovMap([branch(fs[i],dsm[i],ran;dir=dir) for i in eachindex(fs)],
        Segment(minimum(first(d) for d in dsm),maximum(last(d) for d in dsm)),Domain(ran))
end

function MarkovMap(fs::AbstractVector,gs::AbstractVector,ds::AbstractVector,ran;dir::AbstractString="fwd")
  @assert length(fs) == length(gs)
  @assert length(fs) == length(ds)
  dsm = [Domain(d) for d in ds]
  @compat MarkovMap([branch(fs[i],gs[i],dsm[i],ran;dir=dir) for i in eachindex(fs)],
        Segment(minimum(first(d) for d in dsm),maximum(last(d) for d in dsm)),Domain(ran))
end

@compat (m::MarkovMap)(i::Integer,x) = (m.branches[i])(x)
@compat (m::MarkovMap)(x) = (m.branches[getbranch(m,x)])(x)
for FUN in (:mapD,:mapP)
 @eval $FUN(m::MarkovMap,x) = $FUN(m.branches[getbranch(m,x)],x)
end
for FUN in (:mapD,:mapP,:mapinv,:mapinvD,:mapinvP)
  @eval $FUN(m::MarkovMap,i::Integer,x) = $FUN(m.branches[i],x)
end

branches(m) = m.branches
nbranches(m::MarkovMap) = length(m.branches)
nneutral(m::MarkovMap) = sum([isa(b,NeutralBranch) for b in m.branches])
getbranch(m::MarkovMap,x) = in(x,m.domain) ? findfirst([in(x,domain(b)) for b in m.branches]) : throw(DomainError)

# # TODO: maybe roll into branch constructors? maybe remove??
# function MarkovMap{D,R,ff}(
#     f::AbstractVector{ff},dfdx::AbstractVector{ff},dom::D,ran::R)
#   T = eltype(R)
#   bl = Array(T,length(f)); bu = Array(T,length(f))
#   tol = 10eps(maxabs([dom.a,dom.b]))
#   for i = 1:length(f)
#     ba = interval_newton(f[i],dfdx[i],ran.a,dom.a,dom.b,interval_guess(x,dom,ran),tol)
#     bb = interval_newton(f[i],dfdx[i],ran.b,dom.a,dom.b,interval_guess(x,dom,ran),tol)
#     bl[i] = min(ba,bb); bu[i] = max(ba,bb)
#     bl[i] < dom.a && bl[i]-dom.a > -2.5tol && (bl[i] = dom.a)
#     bu[i] > dom.b && bu[i]-dom.b < 2.5tol && (bu[i] = dom.b)
#   end
#   for i = 1:length(f)
#     for j = 1:length(f)
#       abs(bu[j]-bl[i]) < 2.5tol && ((j ==i) ?
#                                       error("Width of branch $i too small for automated branch edge checking...") :
#                                       (bu[j] = bl[i] = (bu[j]+bl[i])/2))
#     end
#   end
#   MarkovMap(f,dfdx,dom,ran,bl,bu)
# end
# #MarkovMap(dom::D,ran::R,f::AbstractVector{ff},dfdx::AbstractVector{ff}) = MarkovMap{D,R,eltype(R),ff}(dom,ran,f,dfdx)
# MarkovMap{ff<:ApproxFun.Fun}(f::AbstractVector{ff},dom::Domain,ran::Domain) = MarkovMap(f,[fi' for fi in f],dom,ran)
#
# # function MarkovMap{ff,gg}(dom::Domain,ran::Domain,f::AbstractVector{ff},dfdx::AbstractVector{gg},args...;kwargs...)
# #   pp = promote_type(ff,gg)
# #   MarkovMap(dom,ran,convert(Vector{pp},f),convert(Vector{pp},dfdx),args...;kwargs...)
# # end
# MarkovMap{ff}(f::AbstractVector{ff},dom::Domain,args...;kwargs...) = MarkovMap(f,dom,dom,args...;kwargs...)


# CircleMaps

abstract AbstractCircleMap{D<:Domain,R<:Domain} <: AbstractMarkovMap{D,R}

immutable FwdCircleMap{D<:Domain,R<:Domain,ff,gg,T} <: AbstractCircleMap{D,R}
  f::ff
  dfdx::gg
  domain::D
  rangedomain::R
  cover::Int
  fa::T
  fb::T

  function FwdCircleMap(f,dfdx,domd,randm)
    # @assert isempty(∂(randm)) isempty(∂(domd))
    fa = f(first(domd)); fb = f(last(domd))
    cover_est = (fb-fa)/arclength(randm)
    cover_integer = round(Int,cover_est)
    cover_est ≈ cover_integer || error("Circle map lift does not have integer covering number.")
    new(f,dfdx,domd,randm,abs(cover_integer),fa,fb)
  end
end
function FwdCircleMap{ff,gg}(f::ff,dfdx::gg,dom,ran)
  domd = PeriodicDomain(dom); randm = PeriodicDomain(ran)
  FwdCircleMap{typeof(domd),typeof(randm),ff,gg,eltype(domd)}(f,dfdx,domd,randm)
end

@compat (m::FwdCircleMap)(x) = mod(m.f(x),m.rangedomain)
mapD(m::FwdCircleMap,x) = m.dfdx(x)
@compat mapP(m::FwdCircleMap,x) = (m(x),m.dfdx(x))

mapinv(m::FwdCircleMap,i::Integer,y) = mod(domain_newton(m.f,m.dfdx,interval_mod(y+i*arclength(m.rangedomain),m.fa,m.fb),
    m.domain),m.domain)
mapinvD(m::FwdCircleMap,i::Integer,y) = m.dfdx(mapinv(m,i,y))
function mapinvP(m::FwdCircleMap,i::Integer,y)
  x = mapinv(m,i,y)
  (x,inv(m.dfdx(x)))
end


immutable RevCircleMap{D<:Domain,R<:Domain,ff,gg,T} <: AbstractCircleMap{D,R}
  v::ff
  dvdx::gg
  domain::D
  rangedomain::R
  cover::Int
  va::T
  vb::T

  function RevCircleMap(v,dvdx,domd,randm)

    # @assert isempty(∂(ran)) isempty(∂(dom))
    ra = first(randm); va = v(ra)
    dr = arclength(randm); dd = arclength(domd)
    cover = 1; vr = v(ra+dr)-va
    while (abs(vr) <= dd && cover < 10000)
      vr = v(ra+cover*dr)-va
      abs(vr) ≈ dd && break
      abs(vr) > dd && error("Inverse lift doesn't appear to have an inverse")
      cover += 1
    end
    cover == 10000 && error("Can't get to the end of the inverse lift after 10000 steps")

    new(v,dvdx,domd,randm,cover,va,v(last(randm)))
  end
end
function RevCircleMap{ff,gg}(v::ff,dvdx::gg,dom,ran)
  domd = PeriodicDomain(dom); randm = PeriodicDomain(ran)
  RevCircleMap{typeof(domd),typeof(randm),ff,gg,eltype(randm)}(v,dvdx,domd,randm)
end

@compat (m::RevCircleMap)(x) = domain_newton(m.v,m.dvdx,interval_mod(x,m.va,m.vb),m.rangedomain)
@compat mapD(m::RevCircleMap,x) = inv(m.dvdx(m(x)))
function mapP(m::RevCircleMap,x)
  @compat y = m(x)
  (y,inv(m.dvdx(y)))
end

mapinv(m::RevCircleMap,i::Integer,y) = m.v(y+i*arclength(m.rangedomain))
mapinvD(m::RevCircleMap,i::Integer,y) = m.dvdx(y+i*arclength(m.rangedomain))
function mapinvP(m::RevCircleMap,i::Integer,y)
  ys = y+i*arclength(m.rangedomain)
  (m.v(ys),m.dvdx(ys))
end




# autodiff
FwdCircleMap(f,d,r) = FwdCircleMap(f,autodiff_dual(f,d),d,r);
RevCircleMap(f,d,r) = RevCircleMap(f,autodiff_dual(f,r),d,r);
CircleMap(f,d,r;dir::AbstractString="fwd") = dir == "fwd" ?
  FwdCircleMap(f,d,r) : RevCircleMap(f,d,r)



CircleMap(f,dfdx,dom,ran;dir::AbstractString="fwd") =
      dir == "fwd" ? FwdCircleMap(f,dfdx,dom,ran) : RevCircleMap(f,dfdx,dom,ran)

ncover(m::AbstractCircleMap) = m.cover

#mapDsign(m::MarkovMap,i::Integer) = m.sgns[i]

#getindex(m::InverseDerivativeMarkovMap,:dvdx) = m.dvdx






# Inducing

immutable InducedMarkovMap{M<:MarkovMap,B<:MarkovBranch,D<:Domain,R<:Domain} <: AbstractMarkovMap{D,R}
  m::M
  b::B
  domain::D
  rangedomain::R
  function InducedMarkovMap(m,b,dom,ran) #requires m,b: their domains -> m ∪ b
    @assert dom == ran
    @assert domain(m) == dom
    @assert rangedomain(b) == rangedomain(m)
    @assert domain(m) == setdiff(rangedomain(m),domain(b))
    new(m,b,dom,ran)
  end
end
InducedMarkovMap(m::MarkovMap,b::MarkovBranch,dom::Domain,ran::Domain) =
  InducedMarkovMap{typeof(m),typeof(b),typeof(dom),typeof(ran)}(m,b,dom,ran)

function mapinduceP(b::MarkovBranch,x) #hack
  y = copy(x)
  dy = one(y)
  while in(y,b.domain)
    p = unsafe_mapP(b,y)
    y == p[1] && error("Map cannot be induced at this point as a fixed point is in its forward orbit")
    y = p[1]
    dy *= p[2]
  end
  (y,dy)
end
mapinduce(b::MarkovBranch,x) = mapinduceP(b,x)[1]
mapinduceD(b::MarkovBranch,x) = mapinduceP(b,x)[2]


function induce(m::MarkovMap,n::Integer)
  @assert domain(m) == rangedomain(m)
  b = m.branches[n]
  dom = setdiff(m.domain,b.domain)
  InducedMarkovMap(MarkovMap(m.branches[setdiff(1:nbranches(m),n)],dom,m.rangedomain),b,dom,dom)
end
nneutral(m::InducedMarkovMap) = nneutral(m.m) # if your maps stop being uniformly expanding this is bad

function mapP(m::InducedMarkovMap,x)
  y = mapP(m.m,x)
  if in(y[1],domain(m.b))
    a = mapinduceP(m.b,y[1])
    y = [a[1],y[2]*a[2]]
  end
  y
end
@compat (m::InducedMarkovMap)(x) = mapP(m,x)[1]
mapD(m::InducedMarkovMap,x) = mapP(m,x)[2]




# Domain calls

for TYP in (:MarkovMap,:InducedMarkovMap,:FwdCircleMap,:RevCircleMap)
  @eval ApproxFun.domain(m::$TYP) = m.domain
  @eval rangedomain(m::$TYP) = m.rangedomain
end

# InverseCache

# type MarkovInverseCache{M<:AbstractMarkovMap,S<:Space,T} <: AbstractMarkovMap
#   m::M
#   sp::S
#   cache::Dict{Int,Array{T,2}}
# end
# function MarkovInverseCache(m::AbstractMarkovMap,s::Space)
#   @assert rangedomain(m) == domain(s)
#   MarkovInverseCache{typeof(m),typeof(s),eltype(domain(m))}(m,s,Dict{Int,Array{eltype(domain(m)),2}}())
# end
#
# MarkovInverseCache(m::AbstractMarkovMap) = MarkovInverseCache(m,ApproxFun.Space(rangedomain(m)))
#
# ApproxFun.domain(mc::MarkovInverseCache) = domain(mc.m)
# rangedomain(mc::MarkovInverseCache) = rangedomain(mc.m)
# length(mc::MarkovInverseCache) = length(mc.m)
# rangespace(mc::MarkovInverseCache) = mc.sp
# function extenddata!(m::MarkovInverseCache,n::Int)
#   v = Array(eltype(m),length(m),n)
#   pts = points(rangespace(m),n)
#   for k = 1:n
#     for i = 1:length(m)
#       v[i,k] = mapinv(m.m,i,pts[k])
#     end
#   end
#   push!(m.cache,n=>v)
# end
#
# for FN in (:mapinv,:mapinvD)
#   @eval $FN(m::MarkovInverseCache,i::Integer,x) = $FN(m.m,i,x)
# end
#
# function mapinv(m::MarkovInverseCache,i::Integer,x::InterpolationNode)
#   rangespace(m) != space(x) && return mapinv(m,i,convert(eltype(x),x))
#   ~haskey(m.cache,x.n) && extenddata!(m,x.n)
#   m.cache[x.n][i,x.k]
# end
# # mapinvD{M<:InverseDerivativeMarkovMap}(m::MarkovInverseCache{M},i::Integer,x::InterpolationNode) =
# #   mapinvD(m.m,i,x)
# mapinvD(m::MarkovInverseCache,i::Integer,x::InterpolationNode) =
#   isa(m.branches[i],RevExpandingBranch) ? mapinvD(m.m,i,mapinv(m,i,x)) : inv(mapD(m.m,i,mapinv(m,i,x)))
# # mapDsign(m::MarkovInverseCache,i::Integer) = mapDsign(m.m,i)
