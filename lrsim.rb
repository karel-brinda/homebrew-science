class Lrsim < Formula
  desc "10x Genomics Reads Simulator"
  homepage "https://github.com/aquaskyline/LRSIM"
  url "https://github.com/aquaskyline/LRSIM/archive/1.0.tar.gz"
  sha256 "89623fba2ce624da4e2c8ce8a99b1a46eb3bc03a8c38044c64f4b8a0d0d9721e"
  # tag "bioinformatics"

  bottle do
    cellar :any
    sha256 "3208017c9a2d094ba74dbe9a5d9e8a7313a14bc81d84c7ba31a8e78c058d5450" => :sierra
    sha256 "f7029c0561c10ce77985ed18ff2b2d910f90912e161a1e180d6484692a963299" => :el_capitan
    sha256 "8b811b62134ca56ca50911457fd55eca4a6cdda3e46da1dc70f68408d821614e" => :yosemite
    sha256 "da58a2b4da11f2c59e9b6b422b34839dd877f82615fa39d5d6594e6e9e0109a2" => :x86_64_linux
  end

  depends_on "samtools"

  # error: use of undeclared identifier 'direct_insert_aux'
  fails_with :clang

  resource "Parse::RecDescent" do
    url "https://cpan.metacpan.org/authors/id/J/JT/JTBRAUN/Parse-RecDescent-1.967015.tar.gz"
    sha256 "1943336a4cb54f1788a733f0827c0c55db4310d5eae15e542639c9dd85656e37"
  end

  resource "File::ShareDir::Install" do
    url "https://cpan.metacpan.org/authors/id/E/ET/ETHER/File-ShareDir-Install-0.11.tar.gz"
    sha256 "32bf8772e9fea60866074b27ff31ab5bc3f88972d61915e84cbbb98455e00cc8"
  end

  resource "Inline" do
    url "https://cpan.metacpan.org/authors/id/I/IN/INGY/Inline-0.80.tar.gz"
    sha256 "7e2bd984b1ebd43e336b937896463f2c6cb682c956cbd2c311a464363d2ccef6"
  end

  resource "Inline::C" do
    url "https://cpan.metacpan.org/authors/id/T/TI/TINITA/Inline-C-0.78.tar.gz"
    sha256 "9a7804d85c01a386073d2176582b0262b6374c5c0341049da3ef84c6f53efbc7"
  end

  resource "Math::Random" do
    url "https://www.cpan.org/authors/id/G/GR/GROMMEL/Math-Random-0.72.tar.gz"
    sha256 "be0522328811d96de505d9ebac3d096359026fa8d5c38f7bb999a78ec5bc254c"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    resources.each do |res|
      res.stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        system "make", "PERL5LIB=#{ENV["PERL5LIB"]}"
        system "make", "install"
      end
    end

    inreplace "simulateLinkedReads.pl", "#!/usr/bin/perl", "#!/usr/bin/env perl" unless OS.mac?

    system "make", "extractReads"

    cd "DWGSIMSrc" do
      # Fix ld: symbol(s) not found
      inreplace Dir["src/*.c", "samtools/*.c"], "inline ", "", false
      system "make", "-C", "samtools/bcftools", "clean"
      system "make"
    end

    cd "msortSrc" do
      # Fix error: use of undeclared identifier 'direct_insert_aux'
      system "make", "CXXFLAGS=-fpermissive", "msort.o", "sort_funs.o", "stdhashc.o"
      system ENV.cxx, "-o", "msort", "msort.o", "sort_funs.o", "stdhashc.o"
    end

    cd "SURVIVORSrc/Debug" do
      system "make"
    end

    prefix.install "DWGSIMSrc/dwgsim", "extractReads", "msortSrc/msort", "SURVIVORSrc/Debug/SURVIVOR",
      "faFilter.pl", "simulateLinkedReads.pl",
      "4M-with-alts-february-2016.txt"
    (bin/"simulateLinkedReads").write_env_script(prefix/"simulateLinkedReads.pl", :PERL5LIB => ENV["PERL5LIB"])
    prefix.install_symlink HOMEBREW_PREFIX/"bin/samtools"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/simulateLinkedReads -h 2>&1", 2)
  end
end
