# CDDLib

| **Build Status** | **References to cite** |
|:----------------:|:----------------------:|
| [![Build Status][build-img]][build-url] [![Build Status][winbuild-img]][winbuild-url] | [![DOI][zenodo-img]][zenodo-url] |
| [![Coveralls branch][coveralls-img]][coveralls-url] [![Codecov branch][codecov-img]][codecov-url] | |

CDDLib is a wrapper for [cdd](https://www.inf.ethz.ch/personal/fukudak/cdd_home/). This module can either be used in a "lower level" using the API of cdd or using the higher level interface of [Polyhedra](https://github.com/JuliaPolyhedra/Polyhedra.jl).
CDDLib also includes the linear programming solver `CDDLib.Optimizer` which can be used by [JuMP](https://github.com/JuliaOpt/JuMP.jl) through [MathOptInterface](https://github.com/JuliaOpt/MathOptInterface.jl).

Building the package will download binaries of [`cddlib`](https://github.com/cddlib/cddlib)
that are compiled by [cddlibBuilder](https://github.com/JuliaPolyhedra/cddlibBuilder/).

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

[build-img]: https://travis-ci.org/JuliaPolyhedra/CDDLib.jl.svg?branch=master
[build-url]: https://travis-ci.org/JuliaPolyhedra/CDDLib.jl
[winbuild-img]: https://ci.appveyor.com/api/projects/status/s03l5r1o96l9acha?svg=true
[winbuild-url]: https://ci.appveyor.com/project/JuliaPolyhedra/cddlib-jl
[coveralls-img]: https://coveralls.io/repos/github/JuliaPolyhedra/CDDLib.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaPolyhedra/CDDLib.jl?branch=master
[codecov-img]: http://codecov.io/github/JuliaPolyhedra/CDDLib.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaPolyhedra/CDDLib.jl?branch=master

[zenodo-url]: https://doi.org/10.5281/zenodo.1214581
[zenodo-img]: https://zenodo.org/badge/DOI/10.5281/zenodo.1214581.svg
