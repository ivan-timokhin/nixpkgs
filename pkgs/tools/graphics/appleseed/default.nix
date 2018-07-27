{ stdenv, fetchFromGitHub, cmake, boost165, pkgconfig, guile,
eigen3_3, libpng, python, libGLU, qt4, openexr, openimageio,
opencolorio, xercesc, ilmbase, osl, seexpr
}:

let boost_static = boost165.override {
  enableStatic = true;
  enablePython = true;
};
in stdenv.mkDerivation rec {

  name = "appleseed-${version}";
  version = "1.9.0-beta";

  src = fetchFromGitHub {
    owner  = "appleseedhq";
    repo   = "appleseed";
    rev    = "1.9.0-beta";
    sha256 = "0m7zvfkdjfn48zzaxh2wa1bsaj4l876a05bzgmjlfq5dz3202anr";
  };
  buildInputs = [
    cmake pkgconfig boost_static guile eigen3_3 libpng python
    libGLU qt4 openexr openimageio opencolorio xercesc
    osl seexpr
  ];

  NIX_CFLAGS_COMPILE = "-I${openexr.dev}/include/OpenEXR -I${ilmbase.dev}/include/OpenEXR -I${openimageio.dev}/include/OpenImageIO";

  cmakeFlags = [
      "-DUSE_EXTERNAL_XERCES=ON" "-DUSE_EXTERNAL_OCIO=ON" "-DUSE_EXTERNAL_OIIO=ON"
      "-DUSE_EXTERNAL_OSL=ON" "-DWITH_CLI=ON" "-DWITH_STUDIO=ON" "-DWITH_TOOLS=ON"
      "-DUSE_EXTERNAL_PNG=ON" "-DUSE_EXTERNAL_ZLIB=ON"
      "-DUSE_EXTERNAL_EXR=ON" "-DUSE_EXTERNAL_SEEXPR=ON"
      "-DWITH_PYTHON=ON"
      "-DWITH_DISNEY_MATERIAL=ON"
      "-DUSE_SSE=ON"
      "-DUSE_SSE42=ON"
  ];
  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Open source, physically-based global illumination rendering engine";
    homepage = https://appleseedhq.net/;
    maintainers = with maintainers; [ hodapp ];
    license = licenses.mit;
    platforms = platforms.linux;
  };

  # Work around a bug in the CMake build:
  postInstall = ''
    chmod a+x $out/bin/*
  '';
}

# TODO: Is the below problematic?

# CMake Warning (dev) at /nix/store/dsyw2zla2h3ld2p0jj4cv0j3wal1bp3h-cmake-3.11.2/share/cmake-3.11/Modules/FindOpenGL.cmake:270 (message):
#  Policy CMP0072 is not set: FindOpenGL prefers GLVND by default when
#  available.  Run "cmake --help-policy CMP0072" for policy details.  Use the
#  cmake_policy command to set the policy and suppress this warning.
#
#  FindOpenGL found both a legacy GL library:
#
#    OPENGL_gl_LIBRARY: /nix/store/yxrgmcz2xlgn113wz978a91qbsy4rc8g-libGL-1.0.0/lib/libGL.so
#
#  and GLVND libraries for OpenGL and GLX:
#
#    OPENGL_opengl_LIBRARY: /nix/store/yxrgmcz2xlgn113wz978a91qbsy4rc8g-libGL-1.0.0/lib/libOpenGL.so
#    OPENGL_glx_LIBRARY: /nix/store/yxrgmcz2xlgn113wz978a91qbsy4rc8g-libGL-1.0.0/lib/libGLX.so
#
#  OpenGL_GL_PREFERENCE has not been set to "GLVND" or "LEGACY", so for
#  compatibility with CMake 3.10 and below the legacy GL library will be used.
