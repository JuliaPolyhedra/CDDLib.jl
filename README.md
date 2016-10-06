# CDDLib

[![Build Status](https://travis-ci.org/blegat/CDDLib.jl.svg?branch=master)](https://travis-ci.org/blegat/CDDLib.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/bfcfmeq2yxn3bj07?svg=true)](https://ci.appveyor.com/project/blegat/cdd-jl/settings/badges)
[![Coverage Status](https://coveralls.io/repos/github/blegat/CDDLib.jl/badge.svg?branch=master)](https://coveralls.io/github/blegat/CDDLib.jl?branch=master)
[![codecov.io](http://codecov.io/github/blegat/CDDLib.jl/coverage.svg?branch=master)](http://codecov.io/github/blegat/CDDLib.jl?branch=master)

CDDLib.jl is a wrapper for [cdd](https://www.inf.ethz.ch/personal/fukudak/cdd_home/). This module can either be used in a "lower level" using the API of cdd or using the higher level interface of [Polyhedra.jl](https://github.com/blegat/Polyhedra.jl).
I needed to fork cddlib to write the wrapper because it is interface is text file based.
My changes are not upstream yet, the version used by CDDLib.jl can be found [here](https://github.com/blegat/cddlib).

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
