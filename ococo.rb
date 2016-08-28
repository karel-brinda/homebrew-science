class Ococo < Formula
  desc "Ococo, the first online consensus caller"
  homepage "https://github.com/karel-brinda/ococo"
  url "https://github.com/karel-brinda/ococo/archive/#{version}.tar.gz"
  version "0.1.2.1"
  sha256 "9fb55b1fad3647bc651a638851fe39c5c7151a0718034f22bf3129e29a1d965e"

  head "https://github.com/karel-brinda/ococo.git"

  depends_on "htslib"

  def install
    system ["make", "HTSLIBINCLUDE=#{Formula["htslib"].opt_prefix}/include", "HTSLIB=#{Formula["htslib"].opt_prefix}/lib/libhts.a"]
    bin.install "ococo"
    man1.install "ococo.1"
  end

  test do
    system"#{bin}/ococo -v"
  end
end
