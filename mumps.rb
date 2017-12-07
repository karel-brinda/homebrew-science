class Mumps < Formula
  desc "Parallel Sparse Direct Solver"
  homepage "http://mumps-solver.org"
  url "http://mumps.enseeiht.fr/MUMPS_5.0.1.tar.gz"
  mirror "http://graal.ens-lyon.fr/MUMPS/MUMPS_5.0.1.tar.gz"
  sha256 "50355b2e67873e2239b4998a46f2bbf83f70cdad6517730ab287ae3aae9340a0"
  revision 4

  bottle do
    cellar :any
    sha256 "eeaaf0e5cd4bd4e0ef3aefa142867e65635df2a78f6519e0422c2eefaeb29d6a" => :el_capitan
    sha256 "8f2faaf6abac6b1e19dcda7cbc1331275b2c3588d1f9b247ebc63e6870770e62" => :yosemite
    sha256 "e7a7b0e17d710f9f88941de2f40f521ac0f091e92a7e3c8853562e51b8001337" => :mavericks
  end

  depends_on mpi: [:cc, :cxx, :f90, :recommended]
  if build.with? "mpi"
    depends_on "scalapack" => (build.with? "openblas") ? ["with-openblas"] : []
  end
  depends_on "metis"    => :optional if build.without? "mpi"
  depends_on "parmetis" => :optional if build.with? "mpi"
  depends_on "scotch5"  => :optional
  depends_on "scotch"   => :optional

  depends_on "openblas" => :optional
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  depends_on :fortran

  resource "mumps_simple" do
    url "https://github.com/dpo/mumps_simple/archive/v0.4.tar.gz"
    sha256 "87d1fc87eb04cfa1cba0ca0a18f051b348a93b0b2c2e97279b23994664ee437e"
  end

  def install
    make_args = ["RANLIB=echo"]
    if OS.mac?
      # Building dylibs with mpif90 causes segfaults on 10.8 and 10.10. Use gfortran.
      shlibs_args = ["LIBEXT=.dylib",
                     "AR=#{ENV["FC"]} -dynamiclib -Wl,-install_name -Wl,#{lib}/$(notdir $@) -undefined dynamic_lookup -o "]
    else
      shlibs_args = ["LIBEXT=.so",
                     "AR=$(FL) -shared -Wl,-soname -Wl,$(notdir $@) -o "]
    end
    make_args += ["OPTF=-O", "CDEFS=-DAdd_"]
    orderingsf = "-Dpord"

    makefile = (build.with? "mpi") ? "Makefile.G95.PAR" : "Makefile.G95.SEQ"
    cp "Make.inc/" + makefile, "Makefile.inc"

    if build.with? "scotch5"
      make_args += ["SCOTCHDIR=#{Formula["scotch5"].opt_prefix}",
                    "ISCOTCH=-I#{Formula["scotch5"].opt_include}"]

      if build.with? "mpi"
        scotch_libs = "LSCOTCH=-L$(SCOTCHDIR)/lib -lptesmumps -lptscotch -lptscotcherr"
        scotch_libs += " -lptscotchparmetis" if build.with? "parmetis"
        make_args << scotch_libs
        orderingsf << " -Dptscotch"
      else
        scotch_libs = "LSCOTCH=-L$(SCOTCHDIR) -lesmumps -lscotch -lscotcherr"
        scotch_libs += " -lscotchmetis" if build.with? "metis"
        make_args << scotch_libs
        orderingsf << " -Dscotch"
      end
    elsif build.with? "scotch"
      make_args += ["SCOTCHDIR=#{Formula["scotch"].opt_prefix}",
                    "ISCOTCH=-I#{Formula["scotch"].opt_include}"]

      if build.with? "mpi"
        scotch_libs = "LSCOTCH=-L$(SCOTCHDIR)/lib -lptscotch -lptscotcherr -lptscotcherrexit -lscotch"
        scotch_libs += "-lptscotchparmetis" if build.with? "parmetis"
        make_args << scotch_libs
        orderingsf << " -Dptscotch"
      else
        scotch_libs = "LSCOTCH=-L$(SCOTCHDIR) -lscotch -lscotcherr -lscotcherrexit"
        scotch_libs += "-lscotchmetis" if build.with? "metis"
        make_args << scotch_libs
        orderingsf << " -Dscotch"
      end
    end

    if build.with? "parmetis"
      make_args += ["LMETISDIR=#{Formula["parmetis"].opt_lib}",
                    "IMETIS=#{Formula["parmetis"].opt_include}",
                    "LMETIS=-L#{Formula["parmetis"].opt_lib} -lparmetis -L#{Formula["metis"].opt_lib} -lmetis"]
      orderingsf << " -Dparmetis"
    elsif build.with? "metis"
      make_args += ["LMETISDIR=#{Formula["metis"].opt_lib}",
                    "IMETIS=#{Formula["metis"].opt_include}",
                    "LMETIS=-L#{Formula["metis"].opt_lib} -lmetis"]
      orderingsf << " -Dmetis"
    end

    make_args << "ORDERINGSF=#{orderingsf}"

    if build.with? "mpi"
      make_args += ["CC=#{ENV["MPICC"]} -fPIC",
                    "FC=#{ENV["MPIFC"]} -fPIC",
                    "FL=#{ENV["MPIFC"]} -fPIC",
                    "SCALAP=-L#{Formula["scalapack"].opt_lib} -lscalapack",
                    "INCPAR=", # Let MPI compilers fill in the blanks.
                    "LIBPAR=$(SCALAP)"]
    else
      make_args += ["CC=#{ENV["CC"]} -fPIC",
                    "FC=#{ENV["FC"]} -fPIC",
                    "FL=#{ENV["FC"]} -fPIC"]
    end

    if build.with? "openblas"
      make_args << "LIBBLAS=-L#{Formula["openblas"].opt_lib} -lopenblas"
    elsif build.with? "veclibfort"
      make_args << "LIBBLAS=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
    else
      make_args << "LIBBLAS=-lblas -llapack"
    end

    ENV.deparallelize # Build fails in parallel on Mavericks.

    system "make", "alllib", *(shlibs_args + make_args)

    lib.install Dir["lib/*"]
    lib.install ("libseq/libmpiseq" + (OS.mac? ? ".dylib" : ".so")) if build.without? "mpi"

    # Build static libraries (e.g., for Dolfin)
    system "make", "alllib", *make_args
    (libexec/"lib").install Dir["lib/*.a"]
    (libexec/"lib").install "libseq/libmpiseq.a" if build.without? "mpi"

    inreplace "examples/Makefile" do |s|
      s.change_make_var! "libdir", lib
    end

    libexec.install "include"
    include.install_symlink Dir[libexec/"include/*"]
    # The following .h files may conflict with others related to MPI
    # in /usr/local/include. Do not symlink them.
    (libexec/"include").install Dir["libseq/*.h"] if build.without? "mpi"

    doc.install Dir["doc/*.pdf"]
    pkgshare.install "examples"

    prefix.install "Makefile.inc"  # For the record.
    File.open(prefix/"make_args.txt", "w") do |f|
      f.puts(make_args.join(" "))  # Record options passed to make.
    end

    if build.with? "mpi"
      resource("mumps_simple").stage do
        simple_args = ["CC=#{ENV["MPICC"]}", "prefix=#{prefix}", "mumps_prefix=#{prefix}",
                       "scalapack_libdir=#{Formula["scalapack"].opt_lib}"]
        if build.with? "scotch5"
          simple_args += ["scotch_libdir=#{Formula["scotch5"].opt_lib}",
                          "scotch_libs=-L$(scotch_libdir) -lptesmumps -lptscotch -lptscotcherr"]
        elsif build.with? "scotch"
          simple_args += ["scotch_libdir=#{Formula["scotch"].opt_lib}",
                          "scotch_libs=-L$(scotch_libdir) -lptscotch -lptscotcherr -lscotch"]
        end
        simple_args += ["blas_libdir=#{Formula["openblas"].opt_lib}",
                        "blas_libs=-L$(blas_libdir) -lopenblas"] if build.with? "openblas"
        system "make", "SHELL=/bin/bash", *simple_args
        lib.install ("libmumps_simple." + (OS.mac? ? "dylib" : "so"))
        include.install "mumps_simple.h"
      end
    end
  end

  def caveats
    s = <<-EOS.undent
      MUMPS was built with shared libraries. If required,
      static libraries are available in
        #{opt_libexec}/lib
    EOS
    if build.without? "mpi"
      s += <<-EOS.undent
      You built a sequential MUMPS library.
      Please add #{libexec}/include to the include path
      when building software that depends on MUMPS.
      EOS
    end
    s
  end

  test do
    ENV.fortran
    cp_r pkgshare/"examples", testpath
    opts = ["-I#{opt_include}", "-L#{opt_lib}", "-lmumps_common"]
    if Tab.for_name("mumps").with? "openblas"
      opts << "-L#{Formula["openblas"].opt_lib}" << "-lopenblas"
    elsif OS.mac?
      opts << "-L#{Formula["veclibfort"].opt_lib}" << "-lvecLibFort"
    else
      opts << "-lblas" << "-llapack"
    end
    if Tab.for_name("mumps").with?("mpi")
      f90 = "mpif90"
      cc = "mpicc"
      mpirun = "mpirun -np #{Hardware::CPU.cores}"
    else
      f90 = ENV["FC"]
      cc = ENV["CC"]
      mpirun = ""
    end

    cd testpath/"examples" do
      system f90, "-o", "ssimpletest", "ssimpletest.F", "-lsmumps", *opts
      system "#{mpirun} ./ssimpletest < input_simpletest_real"
      system f90, "-o", "dsimpletest", "dsimpletest.F", "-ldmumps", *opts
      system "#{mpirun} ./dsimpletest < input_simpletest_real"
      system f90, "-o", "csimpletest", "csimpletest.F", "-lcmumps", *opts
      system "#{mpirun} ./csimpletest < input_simpletest_cmplx"
      system f90, "-o", "zsimpletest", "zsimpletest.F", "-lzmumps", *opts
      system "#{mpirun} ./zsimpletest < input_simpletest_cmplx"
      system cc, "-c", "c_example.c", "-I#{opt_include}"
      system f90, "-o", "c_example", "c_example.o", "-ldmumps", *opts
      system "#{mpirun} ./c_example"
    end
  end
end
