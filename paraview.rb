class Paraview < Formula
  desc "Multi-platform data analysis and visualization application"
  homepage "http://paraview.org"
  revision 2

  head "git://paraview.org/ParaView.git"

  stable do
    url "http://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.2&type=source&os=all&downloadFile=ParaView-v5.2.0.tar.gz"
    sha256 "894e42ef8475bb49e4e7e64f4ee2c37c714facd18bfbb1d6de7f69676b062c96"

    # Patch for hdf5 1.10.0
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/ac788d655f19ab08ba10e7ee82ed28689831cf48/paraview/paraview-5.2.0-hdf5.diff"
      sha256 "ca2cc4befaabaf3daad32129414364fea7b09cb5292d12d92bc1f683131b9e74"
    end
  end

  bottle do
    sha256 "120f2bbf4ca46df7405556512651ae59439d6f9e9a686cb147fb71fa9eb88d69" => :sierra
    sha256 "6e04e207aa8c6e8bff3b3855609b9c5159455b9daf2426271232ce0af59fa3d2" => :el_capitan
    sha256 "591c0a3211fff26b302fcc6476748bea1dbceed6226b5d544fe22c1d6eec1c21" => :yosemite
  end

  depends_on "cmake" => :build

  depends_on "boost" => :recommended
  depends_on "ffmpeg" => :recommended
  depends_on "qt5" => :recommended
  depends_on :mpi => [:cc, :cxx, :optional]
  depends_on :python => :recommended

  depends_on "freetype"
  depends_on "hdf5"
  depends_on "jpeg"
  depends_on "libtiff"
  depends_on "fontconfig"
  depends_on "libpng"

  def install
    dylib = OS.mac? ? "dylib" : "so"

    args = std_cmake_args + %W[
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_TESTING=OFF
      -DMACOSX_APP_INSTALL_PREFIX=#{prefix}
      -DPARAVIEW_DO_UNIX_STYLE_INSTALLS:BOOL=OFF
      -DPARAVIEW_QT_VERSION=5
      -DVTK_USE_SYSTEM_EXPAT:BOOL=ON
      -DVTK_USE_SYSTEM_FREETYPE:BOOL=ON
      -DVTK_USE_SYSTEM_HDF5:BOOL=ON
      -DVTK_USE_SYSTEM_JPEG:BOOL=ON
      -DVTK_USE_SYSTEM_LIBXML2:BOOL=ON
      -DVTK_USE_SYSTEM_PNG:BOOL=ON
      -DVTK_USE_SYSTEM_TIFF:BOOL=ON
      -DVTK_USE_SYSTEM_ZLIB:BOOL=ON
      -DVTK_USE_SYSTEM_ZLIB:BOOL=NETCDF
    ]

    args << "-DPARAVIEW_BUILD_QT_GUI:BOOL=OFF" if build.without? "qt5"
    args << "-DPARAVIEW_USE_MPI:BOOL=ON" if build.with? "mpi"
    args << "-DPARAVIEW_ENABLE_FFMPEG:BOOL=ON" if build.with? "ffmpeg"
    args << "-DPARAVIEW_USE_VISITBRIDGE:BOOL=ON" if build.with? "boost"
    args << "-DPARAVIEW_ENABLE_PYTHON:BOOL=" + ((build.with? "python") ? "ON" : "OFF")

    mkdir "build" do
      # Python3 support is being worked on, see https://gitlab.kitware.com/paraview/paraview/issues/16818
      if build.with? "python"
        python_executable = `which python`.strip
        python_prefix = `#{python_executable} -c 'import sys;print(sys.prefix)'`.chomp
        python_include = `#{python_executable} -c 'from distutils import sysconfig;print(sysconfig.get_python_inc(True))'`.chomp
        python_version = "python" + `#{python_executable} -c 'import sys;print(sys.version[:3])'`.chomp

        args << "-DPYTHON_EXECUTABLE='#{python_executable}'"
        args << "-DPYTHON_INCLUDE_DIR='#{python_include}'"

        # CMake picks up the system's python dylib, even if we have a brewed one.
        if File.exist? "#{python_prefix}/Python"
          args << "-DPYTHON_LIBRARY='#{python_prefix}/Python'"
        elsif File.exist? "#{python_prefix}/lib/lib#{python_version}.a"
          args << "-DPYTHON_LIBRARY='#{python_prefix}/lib/lib#{python_version}.a'"
        elsif File.exist? "#{python_prefix}/lib/lib#{python_version}.#{dylib}"
          args << "-DPYTHON_LIBRARY='#{python_prefix}/lib/lib#{python_version}.#{dylib}'"
        elsif File.exist? "#{python_prefix}/lib/x86_64-linux-gnu/lib#{python_version}.#{dylib}"
          args << "-DPYTHON_LIBRARY='#{python_prefix}/lib/x86_64-linux-gnu/lib#{python_version}.so'"
        else
          odie "No libpythonX.Y.{dylib|so|a} file found!"
        end
      end
      args << ".."

      system "cmake", *args
      system "make", "install"
    end
  end

  test do
    assert_match "paraview version #{version}", shell_output("#{prefix}/paraview.app/Contents/MacOS/paraview --version 2>&1", 0)
  end
end
