# CDDLib

[![](https://github.com/JuliaPolyhedra/CDDLib.jl/workflows/CI/badge.svg?branch=master)](https://github.com/JuliaPolyhedra/CDDLib.jl/actions?query=workflow%3ACI)
[![](http://codecov.io/github/JuliaPolyhedra/CDDLib.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPolyhedra/CDDLib.jl?branch=master)
[![](https://zenodo.org/badge/DOI/10.5281/zenodo.1214581.svg)](https://doi.org/10.5281/zenodo.1214581)

[CDDLib.jl](https://github.com/JuliaPolyhedra/CDDLib.jl) is a wrapper for
[cddlib](https://www.inf.ethz.ch/personal/fukudak/cdd_home/).

CDDLib.jl can be used with C API of cddlib, the higher level interface of [Polyhedra.jl](https://github.com/JuliaPolyhedra/Polyhedra.jl),
or as a linear programming solver with [JuMP](https://github.com/jump-dev/JuMP.jl)
or [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl).

## Problem description

As written in the [README of cddlib](https://github.com/cddlib/cddlib):

> The C-library  cddlib is a C implementation of the Double Description
> Method of Motzkin et al. for generating all vertices (that is, extreme points)
> and extreme rays of a general convex polyhedron in R^d given by a system
> of linear inequalities:
> ```
> P = { x=(x1, ..., xd)^T :  b - A  x  >= 0 }
> ```
> where  A  is a given m x d real matrix, b is a given m-vector
> and 0 is the m-vector of all zeros.
>
> The program can be used for the reverse operation (that is, convex hull
> computation).  This means that  one can move back and forth between
> an inequality representation  and a generator (that is, vertex and ray)
> representation of a polyhedron with cdd.  Also, cdd can solve a linear
> programming problem, that is, a problem of maximizing and minimizing
> a linear function over P.

## License

CDDLib.jl is licensed under the [GPL v2 license](https://github.com/JuliaPolyhedra/CDDLib.jl/blob/master/LICENSE.md).

The underlying solver, [cddlib/cddlib](https://github.com/cddlib/cddlib) is
also licensed under the [GPL v2 license](https://github.com/cddlib/cddlib/blob/master/COPYING).

## Installation

Install CDDLib.jl using the Julia package mangager:

```julia
import Pkg
Pkg.add("CDDLib")
```

Building the package will download binaries of [cddlib](https://github.com/cddlib/cddlib)
that are provided by [cddlib_jll.jl](https://github.com/JuliaBinaryWrappers/cddlib_jll.jl).

## Use with JuMP

Use `CDDLib.Optimizer{Float64}` to use CDDLib.jl with [JuMP](https://github.com/jump-dev/JuMP.jl):

```julia
using JuMP, CDDLib
model = Model(CDDLib.Optimizer{Float64})
```

When using CDDLib.jl with [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl),
you can pass a different number type:
```julia
using MathOptInterface, CDDLib
model = CDDLib.Optimizer{Rational{BigInt}}()
```

## Debugging

CDDLib.jl uses two global Boolean variables to enable debugging outputs: `debug` and
`log`.

You can query the value of `debug` and `log` with `get_debug` and `get_log`,
and set their values with `set_debug` and `set_log`.
