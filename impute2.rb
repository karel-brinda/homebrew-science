class Impute2 < Formula
  desc "Genotype imputation and haplotype phasing program"
  homepage "https://mathgen.stats.ox.ac.uk/impute/impute_v2.html"
  # tag "bioinformatics"
  # doi "10.1371/journal.pgen.1000529"

  version "2.3.2"
  if OS.mac?
    url "https://mathgen.stats.ox.ac.uk/impute/impute_v2.3.2_MacOSX_Intel.tgz"
    sha256 "e91ad1edc66e6174c9dc4fdc06685df7b2d6a9ba4f86477f1a2ceef89a296953"
  elsif OS.linux?
    url "https://mathgen.stats.ox.ac.uk/impute/impute_v2.3.2_x86_64_static.tgz"
    sha256 "95615900464505ddff4251137523740c7f35ac2865eb1eac4d8584ab15a8c45f"
  end

  def install
    bin.install "impute2"
    pkgshare.install "Example"
  end

  test do
    assert_match "IMPUTE version", shell_output("#{bin}/impute2 2>&1", 1)
  end
end
