class Edirect < Formula
  desc "Access NCBI's databases from the shell"
  homepage "http://www.ncbi.nlm.nih.gov/books/NBK179288/"
  url "ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/versions/6.00.20170109/edirect.tar.gz"
  sha256 "b0709d89394ceee1c97bfc44c993ce074181837f79def2c6958edc3e5ffa7d29"
  head "ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/versions/current/edirect.tar.gz"
  # tag "bioinformatics"

  bottle do
    cellar :any_skip_relocation
    sha256 "5aec9857a21f73fd5c527db30cabc47222bfb7d8089cb63f10effbc407f16de4" => :el_capitan
    sha256 "aef2d88463ff0d4974d9953f35f87ba872d4e3e52ff65e8b4778d9502b3c9bd1" => :yosemite
    sha256 "6ce8f0cac378f0706a6c87609dd04fbe11443dc8450f221e6a308aabca309931" => :mavericks
    sha256 "e3c4accf5971c40cce06e82cb2490d7acfbc7735f30d57a330eaf15358baca5d" => :x86_64_linux
  end

  depends_on "HTML::Entities" => :perl
  depends_on "LWP::Simple" => :perl
  depends_on "LWP::Protocol::https" => :perl

  def install
    doc.install "README"
    libexec.install "setup.sh", "setup-deps.pl"
    rm ["Mozilla-CA.tar.gz", "xtract.go"]
    bin.install Dir["*"]
  end

  test do
    system bin/"esearch", "-version"
  end
end
