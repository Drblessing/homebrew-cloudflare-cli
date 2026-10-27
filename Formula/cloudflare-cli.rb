class CloudflareCli < Formula
  desc "Command-line interface for the Cloudflare API and Workers projects"
  homepage "https://developers.cloudflare.com/cf/"
  url "https://registry.npmjs.org/cf/-/cf-1.0.0-beta.23.tgz"
  sha256 "d75ef12542148f061da372ea2160e841110da8a477f7fad22208ce48f1b8c122"
  license any_of: ["Apache-2.0", "MIT"]

  depends_on "node@24"

  conflicts_with "cf", because: "both install a cf executable"
  conflicts_with "cloudfoundry-cli", because: "both install a cf executable"

  resource "npm-shrinkwrap" do
    url "https://raw.githubusercontent.com/Drblessing/homebrew-cloudflare-cli/5febca29246b8cab26dd210755e7fda58366aa1e/Resources/cf/npm-shrinkwrap.json"
    sha256 "005decf6eb096174919a9dc0316914fe30f094fc1cabb0a19bcb58f869ccd2eb"
  end

  def install
    resource("npm-shrinkwrap").stage do
      buildpath.install "npm-shrinkwrap.json"
    end

    # Keep both installation and execution independent of the user's nvm version.
    node = Formula["node@24"]
    ENV.prepend_path "PATH", node.opt_bin
    system node.opt_bin/"npm", "install", *std_npm_args

    %w[cf cloudflare].each do |command|
      (bin/command).write_env_script libexec/"bin"/command, PATH: "#{node.opt_bin}:$PATH"
    end
  end

  def caveats
    <<~EOS
      This community tap packages Cloudflare's beta CLI.
      Existing cf credentials are reused. To sign in for the first time:
        cf auth login

      An older npm installation may shadow the Homebrew command. Check with:
        type -a cf cloudflare
    EOS
  end

  test do
    # Simulate a different Node version selected by nvm earlier on PATH.
    (testpath/"other-node/bin/node").write <<~SH
      #!/bin/sh
      echo "Unexpected Node runtime selected" >&2
      exit 99
    SH
    (testpath/"other-node/bin/node").chmod 0755
    ENV.prepend_path "PATH", testpath/"other-node/bin"

    %w[cf cloudflare].each do |command|
      assert_equal version.to_s, shell_output("#{bin/command} --version").strip
    end

    schema = JSON.parse(shell_output("#{bin}/cf schema zones list"))
    assert_equal "GET", schema.fetch("httpMethod")
    assert_equal "/zones", schema.fetch("path")

    # Exercise the packaged native Workers runtime without a Cloudflare account.
    (testpath/"worker-test.mjs").write <<~JS
      import { createRequire } from "node:module";
      const require = createRequire("#{libexec}/lib/node_modules/cf/package.json");
      const { Miniflare } = require("miniflare");
      const worker = new Miniflare({
        cf: false,
        telemetry: { enabled: false },
        workers: [{
          config: {
            name: "homebrew-test",
            compatibilityDate: "2026-10-23",
            manifest: {
              mainModule: "index.js",
              modules: {
                "index.js": {
                  type: "esm",
                  contents: 'export default { fetch() { return new Response("homebrew-cf-ok"); } };',
                },
              },
            },
          },
          dev: { rootPath: process.cwd(), unsafeRegisterWorker: false },
        }],
      });
      try {
        const response = await worker.dispatchFetch("http://localhost/");
        if (await response.text() !== "homebrew-cf-ok") throw new Error("Worker response mismatch");
      } finally {
        await worker.dispose();
      }
    JS
    system formula_opt_bin("node@24")/"node", testpath/"worker-test.mjs"
  end
end
