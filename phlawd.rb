class Phlawd < Formula
  desc "Phylogenetic dataset construction"
  homepage "http://www.phlawd.net/"
  # doi "10.1186/1471-2148-9-37"

  # The most up to date version of phlawd is the chinchliff fork, which contains
  # a variety of bug fixes and new features. This fork and the (original)
  # blackrim fork will eventually be merged.
  url "https://github.com/chinchliff/phlawd/releases/download/3.4a/phlawd_3.4a_src_with_sqlitewrapped_1.3.1.tar.gz"
  version "3.4a"
  sha256 "0ec8e45359af6e932ea4a042fe4f42ddf05b04689a25df937b2d85db41038253"
  revision 2
  head "https://github.com/chinchliff/phlawd.git"

  bottle do
    cellar :any
    sha256 "a7b98405c068cd47d3182d45a3602ac3ca8ab3b15e0fcc95e7ceab32da5fc9e1" => :el_capitan
    sha256 "68e72f580d7e1096d4913a95e83d69d3dd5435eb31fadd75273db8fbe93618b2" => :yosemite
    sha256 "3702f5dda4d6a607283d81b4efc83dd2cfe0c57d0ec6b8a907f974156e8f26f3" => :mavericks
  end

  fails_with :clang do
    build 600
    cause <<-eos
      PHLAWD requires openmp support, which is not available in clang.
      Currently, PHLAWD can only be compiled with gcc > 4.2.
    eos
  end

  fails_with :llvm do
    cause "The llvm compiler is not supported."
  end

  # correct the makefile to look for dependencies where brew installs them
  patch :DATA

  needs :openmp

  depends_on "mafft"
  depends_on "muscle"
  depends_on "quicktree"
  depends_on "sqlite"

  def install
    # Linux doesn't support -arch
    if OS.linux?
      inreplace "sqlitewrapped-1.3.1/Makefile", "-arch x86_64", ""
      inreplace "src/Makefile.MAC", "-arch x86_64", ""
    end
    # compile sqlitewrapped: a dependency included here since it's uncommon and unmaintained
    system "make", "-C", "sqlitewrapped-1.3.1"

    # compile and install phlawd
    system "make", "-C", "src", "-f", "Makefile.MAC"
    bin.install "src/PHLAWD"
  end

  test do
    # currently developing better tests for the next release
    assert_match version.to_s, shell_output("#{bin}/PHLAWD")
  end
end

__END__
diff --git a/src/Makefile.MAC b/src/Makefile.MAC
index a48def0..4b683dd 100644
--- a/src/Makefile.MAC
+++ b/src/Makefile.MAC
@@ -91,8 +91,7 @@ all: PHLAWD
 # Tool invocations
 PHLAWD: $(OBJS) $(USER_OBJS)
 	@echo 'Building target: $@'
-#	$(CC) $(CFLAGS) -L../deps/mac -L/usr/local/lib -L/usr/lib -o "PHLAWD" $(OBJS) $(USER_OBJS) $(LIBS)
-	$(CC) $(CFLAGS) -L../deps/mac -L/usr/local/lib -o "PHLAWD" $(OBJS) $(USER_OBJS) $(LIBS)
+	$(CC) $(CFLAGS) -L$HOMEBREW_PREFIX/lib -I$HOMEBREW_PREFIX/include -L../sqlitewrapped-1.3.1 -I../sqlitewrapped-1.3.1 -o "PHLAWD" $(OBJS) $(USER_OBJS) $(LIBS)
 	@echo 'Finished building target: $@'
 	@echo ' '
 
