# CDDLib

| **Build Status** | **References to cite** |
|:----------------:|:----------------------:|
| [![Build Status][build-img]][build-url] | [![DOI][zenodo-img]][zenodo-url] |
| [![Codecov branch][codecov-img]][codecov-url] | |

CDDLib is a wrapper for [cdd](https://www.inf.ethz.ch/personal/fukudak/cdd_home/). 

This package can either be used in a "lower level" using the API of cdd or using the 
higher level interface of [Polyhedra](https://github.com/JuliaPolyhedra/Polyhedra.jl).

## Problem description

As written in the [README of cddlib](ftp://ftp.ifor.math.ethz.ch/pub/fukuda/cdd/README.libcdd):

> The C-library  cddlib is a C implementation of the Double Description
> Method of Motzkin et al. for generating all vertices (i.e. extreme points)
> and extreme rays of a general convex polyhedron in R^d given by a system
> of linear inequalities:
>
>    P = { x=(x1, ..., xd)^T :  b - A  x  >= 0 }
>
> where  A  is a given m x d real matrix, b is a given m-vector
> and 0 is the m-vector of all zeros.
>
> The program can be used for the reverse operation (i.e. convex hull
> computation).  This means that  one can move back and forth between
> an inequality representation  and a generator (i.e. vertex and ray)
> representation of a polyhedron with cdd.  Also, cdd can solve a linear
> programming problem, i.e. a problem of maximizing and minimizing
> a linear function over P.


## Installation

```julia
import Pkg
Pkg.add("CDDLib")
```

Building the package will download binaries of [`cddlib`](https://github.com/cddlib/cddlib)
that are compiled by [cddlibBuilder](https://github.com/JuliaPolyhedra/cddlibBuilder/).

## Use with JuMP

Use `CDDLib.Optimizer{Float64}` to use CDDLib with [JuMP](https://github.com/jump-dev/JuMP.jl):
```julia
using JuMP, CDDLib
model = Model(CDDLib.Optimizer{Float64})
```

## Use with MathOptInterface

CDD can also solve problems using `Rational{BigInt}` arithmetic. 

Use `CDDLib.Optimizer{Rational{BigInt}}` to use CDDLib with [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl):
```julia
using MathOptInterface, CDDLib
model = CDDLib.Optimizer{Rational{BigInt}}()
```

[build-img]: https://github.com/JuliaPolyhedra/CDDLib.jl/workflows/CI/badge.svg?branch=master
[build-url]: https://github.com/JuliaPolyhedra/CDDLib.jl/actions?query=workflow%3ACI
[codecov-img]: http://codecov.io/github/JuliaPolyhedra/CDDLib.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaPolyhedra/CDDLib.jl?branch=master

[zenodo-url]: https://doi.org/10.5281/zenodo.1214581
[zenodo-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.1214581.svg
