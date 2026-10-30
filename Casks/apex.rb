cask "apex" do
  version "1.0.0"
  sha256 "f9789f1ee73a2e1b5a08e47402c7244b6cd0cb35a9297e9367fbe0fb0213f375"

  url "https://github.com/MaxSphinx/Apex/releases/download/v#{version}/Apex-#{version}-arm64.dmg"
  name "Apex"
  desc "Ultimate lightweight modular macOS menu bar toolkit for Apple Silicon"
  homepage "https://github.com/MaxSphinx/Apex"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "Apex.app"

  zap trash: [
    "~/Library/Application Support/Apex",
    "~/Library/Caches/com.maxsphinx.apex",
    "~/Library/Preferences/com.maxsphinx.apex.plist",
    "~/Library/Saved Application State/com.maxsphinx.apex.savedState",
  ]
end
