class Monika < Formula
  desc "Synthetic monitoring made easy"
  homepage "https://monika.hyperjump.tech"
  url "https://registry.npmjs.org/@hyperjumptech/monika/-/monika-1.21.2.tgz"
  sha256 "a9280ac4c288a79c77c28263042fab1d4cc785ef08f94d0cfd3cb25b7e40dce4"
  license "MIT"

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "56c00575278cd5392e3a079c4667ba9731137e08a505ce925ec517f4c37f872e"
    sha256 cellar: :any,                 arm64_sonoma:  "f55a93915b6a3fbc0582d69e42a11db79b0211482cc38bc4248990b6fbf6b58d"
    sha256 cellar: :any,                 arm64_ventura: "bbf10fdb8c75aa24ed9e0567fccd363602533db90ec4e64eee89b88b759c1120"
    sha256 cellar: :any,                 sonoma:        "4b9a1158642df00c9cbbea384d4285c65c460f326147f64f8ecf9ecaf81ed0b1"
    sha256 cellar: :any,                 ventura:       "f7b56c62ec781ce7cd4d54d4c2d5312e16c994b4befc1ef5e330c064ccab6f1f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "789fb2bd509df40ca3002bf2886cc560445609517c75d044a991f5d7c3034714"
  end

  depends_on "node"

  on_linux do
    # Workaround for old `node-gyp` that needs distutils.
    # TODO: Remove when `node-gyp` is v10+
    depends_on "python-setuptools" => :build
  end

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]

    # Remove incompatible pre-built binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules = libexec/"lib/node_modules/@hyperjumptech/monika/node_modules"
    node_modules.glob("nice-napi/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }

    cpu_profiler = "@sentry/profiling-node/lib/sentry_cpu_profiler"
    node_modules.glob("#{cpu_profiler}-*")
                .each { |file| rm(file) unless file.basename.to_s.start_with?("sentry_cpu_profiler-#{os}-#{arch}") }
    node_modules.glob("#{cpu_profiler}-*-musl-*").map(&:unlink) if OS.linux?
  end

  test do
    (testpath/"config.yml").write <<~YAML
      notifications:
        - id: 5b3052ed-4d92-4f5d-a949-072b3ebb2497
          type: desktop
      probes:
        - id: 696a3f57-a674-44b5-8125-a62bd2709ac5
          name: 'test brew.sh'
          requests:
            - url: https://brew.sh
              body: {}
              timeout: 10000
    YAML

    monika_stdout = (testpath/"monika.log")
    fork do
      $stdout.reopen(monika_stdout)
      exec bin/"monika", "-r", "1", "-c", testpath/"config.yml"
    end
    sleep 15
    sleep 15 if OS.mac? && Hardware::CPU.intel?

    assert_match "Starting Monika. Probes: 1. Notifications: 1", monika_stdout.read
  end
end
