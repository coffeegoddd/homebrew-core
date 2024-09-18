class Cdo < Formula
  desc "Climate Data Operators"
  homepage "https://code.mpimet.mpg.de/projects/cdo"
  url "https://code.mpimet.mpg.de/attachments/download/29646/cdo-2.4.4.tar.gz"
  sha256 "fc00a71dc83d9c90b172f08e0ae71e1fd3162760461600cd25cf0dfb78ff9453"
  license "GPL-2.0-only"

  livecheck do
    url "https://code.mpimet.mpg.de/projects/cdo/files"
    regex(/href=.*?cdo[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sequoia:  "99ea564f89d7e6f1a5aed780123fa2af8d01e06041474a105273cfd1255313c4"
    sha256 cellar: :any,                 arm64_sonoma:   "a25e82ca7cf9895709729ace682d895bcb6ad1e4b352f1892818a24c5ef708d4"
    sha256 cellar: :any,                 arm64_ventura:  "28d6a461f44bc3ce62d52959cbc9495388574b50b383bfab90a68a40fea9a0df"
    sha256 cellar: :any,                 arm64_monterey: "a849bbef553f5cd4504d9e32f142591343334dc93c1cf409ea3e57f653421c2d"
    sha256 cellar: :any,                 sonoma:         "d92f8dc4653a35d503127cafe05bf6bec0050acee4652c7a6559e0246a47c96f"
    sha256 cellar: :any,                 ventura:        "6819d4f3d7a6c6e6998744b0ee74aa597fb385a726acbc50c0579128db45829d"
    sha256 cellar: :any,                 monterey:       "de7dfd4cb01f9f62a8f86f311fdbb3b382ce7f68638bc23af610be77b61a79ab"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "747b6f8db4306bbdc77ea5da108189d34286b958922c28966d239027a9a0e60f"
  end

  depends_on "eccodes"
  depends_on "hdf5"
  depends_on "libaec"
  depends_on "netcdf"
  depends_on "proj"
  uses_from_macos "python" => :build

  on_macos do
    depends_on "llvm" => :build if DevelopmentTools.clang_build_version <= 1500
  end

  on_linux do
    depends_on "util-linux"
  end

  fails_with :clang do
    build 1500
    cause "Requires C++20 support"
  end

  def install
    ENV.llvm_clang if OS.mac? && DevelopmentTools.clang_build_version <= 1500

    args = %W[
      --disable-openmp
      --with-eccodes=#{Formula["eccodes"].opt_prefix}
      --with-netcdf=#{Formula["netcdf"].opt_prefix}
      --with-hdf5=#{Formula["hdf5"].opt_prefix}
      --with-szlib=#{Formula["libaec"].opt_prefix}
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    data = <<~EOF.unpack1("m")
      R1JJQgABvAEAABz/AAD/gAEBAABkAAAAAAEAAAoAAAAAAAAAAAAgAP8AABIACgB+9IBrbIABLrwA4JwTiBOIQAAAAAAAAXQIgAPEFI2rEBm9AACVLSuNtwvRALldqDul2GV1pw1CbXsdub2q9a/17Yi9o11DE0UFWwRjqsvH80wgS82o3UJ9rkitLcPgxJDVaO9No4XV6EWNPeUSSC7txHi7/aglVaO5uKKtwr2slV5DYejEoKOwpdirLXPIGUAWCya7ntil1amLu4PCtafNp5OpPafFqVWmxaQto72sMzGQJeUxcJkbqEWnOKM9pTOlTafdqPCoc6tAq0WqFarTq2i5M1NdRq2AHWzFpFWj1aJtmAOrhaJzox2nwKr4qQWofaggqz2rkHcog2htuI2YmOB9hZDIpxXA3ahdpzOnDarjqj2k0KlIqM2oyJsjjpODmGu1YtU6WHmNZ5uljcbVrduuOK1DrDWjGKM4pQCmfdVFprWbnVd7Vw1QY1s9VnNzvZiLmGucPZwVnM2bm5yFqb2cHdRQqs2hhZrrm1VGeEQgOduhjbWrqAWfzaANnZOdWJ0NnMWeJQA3Nzc3AAAAAA==
    EOF
    File.binwrite("test.grb", data)
    system bin/"cdo", "-f", "nc", "copy", "test.grb", "test.nc"
    assert_predicate testpath/"test.nc", :exist?
  end
end
