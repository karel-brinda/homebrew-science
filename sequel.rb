class Sequel < Formula
  desc "Improving the Accuracy of Genome Assemblies"
  homepage "http://bix.ucsd.edu/SEQuel/index.html"
  # doi "10.1093/bioinformatics/bts219"
  # tag "bioinformatics"

  url "http://bix.ucsd.edu/SEQuel/download/SEQuel.v102.tar.gz"
  version "1.0.2"
  sha256 "7c2237eb0c99840eee1564e04eedf675219eadea882694b0d349caa38c2a2756"

  depends_on :java
  depends_on "blat"

  def install
    opts = "-Xmx12g"
    jar = "SEQuel.jar"
    prefix.install jar
    bin.write_jar_script prefix/jar, "sequel", opts
    bin.install "blat_wrapper.pl"
    bin.install "prep.pl" => "sequel-prep.pl"
    doc.install "LICENSE", "README"
  end

  def caveats
    <<-EOS.undent
      The helper script prep.pl has been installed as sequel-prep.pl
    EOS
  end

  test do
    assert_match "refinement", shell_output("#{bin}/sequel -h 2>&1", 1)
  end
end
