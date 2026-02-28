#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: scripts/render-brew-formula.sh VERSION SHA256
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

[[ $# -eq 2 ]] || {
  usage
  exit 1
}

version=$1
sha256=$2

[[ -n "$version" ]] || fail "VERSION is required"
[[ -n "$sha256" ]] || fail "SHA256 is required"

cat <<EOF
# typed: false
# frozen_string_literal: true

class RestartToMacos < Formula
  desc "Simple CLI and desktop launcher for one-time restart into macOS on Asahi Linux"
  homepage "https://github.com/jtbrough/restart-to-macos"
  url "https://github.com/jtbrough/restart-to-macos/releases/download/v${version}/restart-to-macos-${version}.tar.gz"
  sha256 "${sha256}"
  license "MIT"

  depends_on :linux

  def install
    system "./install.sh", "--prefix", prefix, "--package-build", "--no-polkit"
  end

  def caveats
    <<~EOS
      restart-to-macos requires asahi-bless from your Linux distro.

      Fedora Asahi:
        sudo dnf install asahi-bless

      Arch/Asahi Arch:
        sudo pacman -S asahi-bless
    EOS
  end

  test do
    system "#{bin}/restart-to-macos", "--help"
  end
end
EOF
