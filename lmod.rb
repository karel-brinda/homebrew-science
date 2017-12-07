class Lmod < Formula
  desc "Lua-based environment modules system to modify PATH variable"
  homepage "https://www.tacc.utexas.edu/research-development/tacc-projects/lmod"
  url "https://github.com/TACC/Lmod/archive/7.5.tar.gz"
  sha256 "855cec83b6c08c2420698ed1c4f0b096a9d3915247c42616249f90af5b112023"

  bottle do
    cellar :any_skip_relocation
    sha256 "d99d45f025566dcdc29f9bab078c1b6fcd5bc912f20d190425c65a67f1a07059" => :sierra
    sha256 "8256c67d07825fc6655af7e950dd098748dea11a456d0cdfe6d2e6caa9634477" => :el_capitan
    sha256 "0d520b5b2186336baee0cdc6678d0ef9c26f07ee63de8fd84210cef73ed64b7a" => :yosemite
    sha256 "68ee9b60c4c1ecd2a3493a6a70d8ef16b898f292f5d5e9f8d204a14684033fe4" => :x86_64_linux
  end

  depends_on "lua"

  resource "luafilesystem" do
    url "https://github.com/keplerproject/luafilesystem/archive/v_1_6_3.tar.gz"
    sha256 "5525d2b8ec7774865629a6a29c2f94cb0f7e6787987bf54cd37e011bfb642068"
  end

  resource "luaposix" do
    url "https://github.com/luaposix/luaposix/archive/v34.0.tar.gz"
    sha256 "ebe638078b9a72f73f0b9b8ae959032e5590d2d6b303e59154be1fb073563f71"
  end

  def install
    luapath = libexec/"vendor"
    ENV["LUA_PATH"] = "#{luapath}/share/lua/5.2/?.lua" \
                      ";#{luapath}/share/lua/5.2/?/init.lua"
    ENV["LUA_CPATH"] = "#{luapath}/lib/lua/5.2/?.so"

    resources.each do |r|
      r.stage do
        system "luarocks", "build", r.name, "--tree=#{luapath}"
      end
    end

    system "./configure",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}"
    system "make", "install"

    # Move prefix/lmod/VERSION/lmod/VERSION/* to prefix/lmod/VERSION/*
    mv Dir[prefix/"lmod/#{version}/*"], prefix
    rmdir prefix/"lmod/#{version}"
    (prefix/"lmod").install_symlink ".." => version
  end

  test do
    system "#{prefix}/lmod/init/sh"
  end
end
