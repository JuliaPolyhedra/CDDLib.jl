using BinDeps

@BinDeps.setup

cddlib_commit = "63a2af7ae1e3fcbaee89594f8c0b6c4eff696bbf"
#cddname = "cddlib-094h"
cddname = "cddlib-$cddlib_commit"

# julia installs libgmp10 but not libgmp-dev since it
# does not have to compile C program with GMP,
# e.g. it does not need the headers.
# FIXME BinDeps doesn't work with header, it only works for libraries because it checks for the .so
#       It sees libgmp.so (installed by libgmp10 as a julia dependency) and thinks that it's ok but
#       it does not have the headers
#libgmpdev = library_dependency("libgmp-dev", aliases=["libgmp"])
libcdd = library_dependency("libcddgmp", aliases=["libcdd-$cddlib_commit"])#, depends=[libgmpdev])

official_repo = "ftp://ftp.ifor.math.ethz.ch/pub/fukuda/cdd/$cddname.tar.gz"
forked_repo = "https://github.com/blegat/cddlib/archive/$cddlib_commit.zip"

#GMP
@linux_only begin
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

#CDD
provides(Sources,
        Dict(URI(forked_repo) => libcdd), unpacked_dir="$cddname")

src_dir = joinpath(BinDeps.srcdir(libcdd), cddname)
libsrc_dir = joinpath(src_dir, "lib-src")
libsrcgmp_dir = joinpath(src_dir, "lib-src-gmp")

includedirs = AbstractString[libsrc_dir, libsrcgmp_dir]
targetdirs = AbstractString["lib-src-gmp/libcddgmp.la","lib-src-gmp/.libs/libcddgmp.la"]
configureopts = AbstractString["CPPFLAGS=-DGMPRATIONAL -I$(libsrc_dir) -I$(libsrcgmp_dir)"]

provides(BuildProcess,
        Dict(
        Autotools(
        libtarget = targetdirs,
        include_dirs = includedirs,
        configure_options = configureopts) => libcdd))

@BinDeps.install Dict(:libcddgmp => :libcdd)
