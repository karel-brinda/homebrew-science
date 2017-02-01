class Libcerf < Formula
  desc "Efficient implementation of complex error functions"
  homepage "http://apps.jcns.fz-juelich.de/doku/sc/libcerf"
  url "http://apps.jcns.fz-juelich.de/src/libcerf/libcerf-1.5.tgz"
  sha256 "e36dc147e7fff81143074a21550c259b5aac1b99fc314fc0ae33294231ca5c86"

  bottle do
    cellar :any
    sha256 "16372609c0c725e5ea4ee9c43ef5c8d99623f60bbd5571947b49a4382f20034b" => :yosemite
    sha256 "c327717cdb1e4ac087f227d9452efc826ddfe5d2eaf14a5e8d1e4d3e65f93fd6" => :mavericks
    sha256 "80f1af3717b8ca7ea6387e0e065eb7bd8a83a0b0c41793f07ddcfc80588b398d" => :mountain_lion
  end

  option "without-test", "Disable build-time testing (not recommended)"

  deprecated_option "without-check" => "without-test"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "check" if build.with? "test"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <cerf.h>
      #include <stdio.h>
      int main()
      {
        printf("%f\\n", voigt(0, 1, 0));
        return -1;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcerf", "-o", "test"
    assert_in_delta `./test`.to_f, 1 / Math.sqrt(2 * Math::PI), 1e-6
  end
end
