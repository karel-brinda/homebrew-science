class Alpscore < Formula
  desc "Applications and Libraries for Physics Simulations"
  homepage "http://alpscore.org"
  url "https://github.com/ALPSCore/ALPSCore/archive/v1.0.0.tar.gz"
  sha256 "2054f47929f3bdb6a0c07fb70e53194f884cdf6c830b737ed5d24312d060b12a"
  revision 1
  head "https://github.com/ALPSCore/ALPSCore.git"

  bottle do
    cellar :any
    sha256 "0de13bb097d1ca2c04fe0c5bb7b5cb1a83c9de028ea3a0521b81852037f17867" => :sierra
    sha256 "54473d533ea9f159e2bf9e639f1ff9d70dcb7f9731f503b642011db45eb7b805" => :el_capitan
    sha256 "d487ac892facfd0244b50ff252cc9c9ffbcc42ce5bd9c83c02ca1c2910e8d386" => :yosemite
  end

  option :cxx11
  option "with-test",   "Build and run shipped tests"
  option "with-doc",    "Build documentation"
  option "with-static", "Build static instead of shared libraries"

  depends_on "cmake" => :build
  depends_on :mpi => [:cc, :cxx, :recommended]

  boost_options = []
  boost_options << "c++11" if build.cxx11?
  depends_on "boost" => boost_options

  depends_on "hdf5" => (build.cxx11? ? ["c++11"] : [])

  def install
    ENV.cxx11 if build.cxx11?
    args = std_cmake_args
    args.delete "-DCMAKE_BUILD_TYPE=None"
    args << "-DCMAKE_BUILD_TYPE=Release"

    if build.with? "static"
      args << "-DALPS_BUILD_STATIC=ON"
      args << "-DALPS_BUILD_SHARED=OFF"
    else
      args << "-DALPS_BUILD_STATIC=OFF"
      args << "-DALPS_BUILD_SHARED=ON"
    end

    args << ("-DENABLE_MPI=" + ((build.with? "mpi") ? "ON" : "OFF"))
    args << ("-DDocumentation=" + ((build.with? "doc") ? "ON" : "OFF"))
    args << ("-DTesting=" + ((build.with? "test") ? "ON" : "OFF"))

    mkdir "tmp" do
      args << ".."
      system "cmake", *args
      system "make"
      system "make", "test" if build.with? "test"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <alps/mc/api.hpp>
      #include <alps/mc/mcbase.hpp>
      #include <alps/accumulators.hpp>
      #include <alps/params.hpp>
      using namespace std;

      int main()
      {
        alps::accumulators::accumulator_set set;
        set << alps::accumulators::FullBinningAccumulator<double>("a");
        set["a"] << 2.9 << 3.1;

        alps::params p;
        p["myparam"] = 1.0;
      }
    EOS
    args_compile = [
      "test.cpp",
      "-lalps-accumulators", "-lalps-hdf5", "-lalps-utilities", "-lalps-params",
      "-lboost_filesystem-mt", "-lboost_system-mt", "-lboost_program_options-mt"
    ]
    args_compile << "-o" << "test"
    system ((build.with? "mpi") ? "mpicxx" : ENV.cxx), *args_compile
    system "./test"
  end
end
