using BinDeps

@BinDeps.setup

cddlib_commit = "82409bb792a0be0a8d57805842a491baf504a3b4"
#cddname = "cddlib-094h"
cddname = "cddlib-$cddlib_commit"

# julia installs libgmp10 but not libgmp-dev since it
# does not have to compile C program with GMP,
# e.g. it does not need the headers.
# FIXME BinDeps doesn't work with header, it only works for libraries because it checks for the .so
#       It sees libgmp.so (installed by libgmp10 as a julia dependency) and thinks that it's ok but
#       it does not have the headers
#libgmpdev = library_dependency("libgmp-dev", aliases=["libgmp"])

#GMP
@static if Sys.islinux()
  const has_apt = try success(`apt-get -v`) catch e false end
  const has_yum = try success(`yum --version`) catch e false end
  const has_pacman = try success(`pacman -Qq`) catch e false end
  if has_apt || has_yum
    if has_apt
      pkgname = "libgmp-dev"
      pkgman = "apt-get"
    else
      pkgname = "libgmp-devel or gmp-devel"
      pkgman = "yum"
    end

    println("Warning: The compilation of cddlib requires the header gmp.h provided by the package $pkgname.")
    println("If the compilation fails, please install it as follows:")
    println("\$ sudo $pkgman install $pkgname")
  end
end
@static if Sys.isapple()
    using Homebrew
    Homebrew.add("gmp")
end
@static if Sys.iswindows()
    using WinRPM
    #libgmp = library_dependency("libgmp", aliases=["libgmp-10"])
    #provides(WinRPM.RPM, "libgmp10", [libgmp], os = :Windows)
    WinRPM.install("libgmp10", yes = true)
end

#CDD

official_repo = "ftp://ftp.ifor.math.ethz.ch/pub/fukuda/cdd/$cddname.tar.gz"
forked_repo = "https://github.com/JuliaPolyhedra/cddlib/archive/$cddlib_commit.zip"
@static if Sys.isunix()
    libcdd = library_dependency("libcddgmp", aliases=["libcdd-$cddlib_commit", "libcddgmp-0"])#, depends=[libgmpdev])
end
@static if Sys.iswindows()
    libcdd = library_dependency("libcddgmp", aliases=["libcddgmp-0"]) #, depends=[libgmp])
    using WinRPM
    push!(WinRPM.sources, "https://cache.julialang.org/http://download.opensuse.org/repositories/home:/blegat:/branches:/windows:/mingw:/win32/openSUSE_Leap_42.2")
    push!(WinRPM.sources, "https://cache.julialang.org/http://download.opensuse.org/repositories/home:/blegat:/branches:/windows:/mingw:/win64/openSUSE_Leap_42.2")
    WinRPM.update()
    provides(WinRPM.RPM, "libcdd-$(cddlib_commit[1:8])", [libcdd], os = :Windows)
end

provides(Sources,
        Dict(URI(forked_repo) => libcdd), unpacked_dir="$cddname")

src_dir = joinpath(BinDeps.srcdir(libcdd), cddname)
libsrc_dir = joinpath(src_dir, "lib-src")
libsrcgmp_dir = joinpath(src_dir, "lib-src-gmp")

includedirs = AbstractString[libsrc_dir, libsrcgmp_dir]
targetdirs = AbstractString["lib-src-gmp/libcddgmp.la","lib-src-gmp/.libs/libcddgmp.la"]
@static if Sys.isapple()
    homebrew_includedir = joinpath(Homebrew.brew_prefix, "include")
    configureopts = AbstractString["CPPFLAGS=-DGMPRATIONAL -I$(libsrc_dir) -I$(libsrcgmp_dir) -I$(homebrew_includedir)"]
    homebrew_libdir = joinpath(Homebrew.brew_prefix, "lib")
    libdirs = AbstractString[homebrew_libdir]
else
    configureopts = AbstractString["CPPFLAGS=-DGMPRATIONAL -I$(libsrc_dir) -I$(libsrcgmp_dir)"]
    libdirs = AbstractString[]  # What to include?
end

provides(BuildProcess,
        Dict(
        Autotools(
        libtarget = targetdirs,
        include_dirs = includedirs,
        lib_dirs = libdirs,
        configure_options = configureopts) => libcdd))

@BinDeps.install Dict(:libcddgmp => :libcdd)
