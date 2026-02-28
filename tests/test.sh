#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(<"$PROJECT_ROOT/VERSION")
TMP_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TMP_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$*"
}

assert_file() {
  local path=$1
  [[ -f "$path" ]] || fail "expected file: $path"
}

assert_not_file() {
  local path=$1
  [[ ! -e "$path" ]] || fail "unexpected path: $path"
}

assert_contains() {
  local path=$1
  local pattern=$2
  grep -Fq -- "$pattern" "$path" || fail "expected '$pattern' in $path"
}

assert_not_contains() {
  local path=$1
  local pattern=$2
  if grep -Fq -- "$pattern" "$path"; then
    fail "did not expect '$pattern' in $path"
  fi
}

make_fake_gui() {
  local dir=$1
  mkdir -p "$dir"
  cat >"$dir/zenity" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$dir/zenity"
}

test_manual_install_layout() {
  local dest="$TMP_ROOT/manual"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /usr/local >/dev/null

  assert_file "$dest/usr/local/bin/restart-to-macos"
  assert_file "$dest/usr/local/bin/restart-to-macos-uninstall"
  assert_file "$dest/usr/local/libexec/restart-to-macos-helper"
  assert_file "$dest/usr/local/share/applications/restart-to-macos.desktop"
  assert_file "$dest/usr/local/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy"
  assert_file "$dest/usr/local/share/restart-to-macos/install-manifest.txt"
  assert_file "$dest/usr/local/share/restart-to-macos/installed-version.txt"
  assert_contains "$dest/usr/local/share/restart-to-macos/installed-version.txt" "$VERSION"
  assert_contains "$dest/usr/local/share/applications/restart-to-macos.desktop" "Exec=/usr/local/bin/restart-to-macos"
  assert_not_contains "$dest/usr/local/share/applications/restart-to-macos.desktop" "$dest"
  pass "manual install layout"
}

test_package_build_layout() {
  local dest="$TMP_ROOT/package"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /usr --package-build >/dev/null

  assert_file "$dest/usr/bin/restart-to-macos"
  assert_file "$dest/usr/libexec/restart-to-macos-helper"
  assert_file "$dest/usr/share/applications/restart-to-macos.desktop"
  assert_file "$dest/usr/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy"
  assert_not_file "$dest/usr/bin/restart-to-macos-uninstall"
  assert_not_file "$dest/usr/share/restart-to-macos/install-manifest.txt"
  assert_not_file "$dest/usr/share/restart-to-macos/installed-version.txt"
  pass "package-build layout"
}

test_no_polkit_install() {
  local dest="$TMP_ROOT/no-polkit"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /usr/local --no-polkit >/dev/null

  assert_file "$dest/usr/local/bin/restart-to-macos"
  assert_file "$dest/usr/local/share/restart-to-macos/install-manifest.txt"
  assert_not_file "$dest/usr/local/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy"
  assert_not_contains "$dest/usr/local/share/restart-to-macos/install-manifest.txt" \
    "io.github.jtbrough.restart-to-macos.policy"
  pass "no-polkit install"
}

test_manual_update_and_uninstall() {
  local work="$TMP_ROOT/update-src"
  local dest="$TMP_ROOT/update-dest"

  cp -a "$PROJECT_ROOT/." "$work"
  "$work/install.sh" --destdir "$dest" --prefix /usr/local >/dev/null
  printf '0.0.9\n' >"$dest/usr/local/share/restart-to-macos/installed-version.txt"
  "$work/install.sh" --destdir "$dest" --prefix /usr/local >/dev/null
  assert_contains "$dest/usr/local/share/restart-to-macos/installed-version.txt" "$VERSION"
  "$work/install.sh" --destdir "$dest" --prefix /usr/local --uninstall >/dev/null
  assert_not_file "$dest/usr/local/bin/restart-to-macos"
  assert_not_file "$dest/usr/local/bin/restart-to-macos-uninstall"
  assert_not_file "$dest/usr/local/libexec/restart-to-macos-helper"
  assert_not_file "$dest/usr/local/share/applications/restart-to-macos.desktop"
  assert_not_file "$dest/usr/local/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy"
  assert_not_file "$dest/usr/local/share/restart-to-macos/install-manifest.txt"
  pass "manual update and uninstall"
}

test_health_check_success() {
  local dest="$TMP_ROOT/check-ok"
  local fakebin="$TMP_ROOT/check-ok-bin"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /usr/local >/dev/null
  make_fake_gui "$fakebin"
  touch "$fakebin/asahi-bless" "$fakebin/pkexec" "$fakebin/systemctl"
  chmod +x "$fakebin/asahi-bless" "$fakebin/pkexec" "$fakebin/systemctl"

  ASAHI_BLESS="$fakebin/asahi-bless" \
  PKEXEC="$fakebin/pkexec" \
  SYSTEMCTL="$fakebin/systemctl" \
  PATH="$fakebin:$PATH" \
  "$dest/usr/local/bin/restart-to-macos" --check >/dev/null

  pass "health check success"
}

test_health_check_fails_without_gui() {
  local dest="$TMP_ROOT/check-no-gui"
  local fakebin="$TMP_ROOT/check-no-gui-bin"
  local output="$TMP_ROOT/check-no-gui.out"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /usr/local >/dev/null
  mkdir -p "$fakebin"
  touch "$fakebin/asahi-bless" "$fakebin/pkexec" "$fakebin/systemctl"
  chmod +x "$fakebin/asahi-bless" "$fakebin/pkexec" "$fakebin/systemctl"

  if ASAHI_BLESS="$fakebin/asahi-bless" \
    PKEXEC="$fakebin/pkexec" \
    SYSTEMCTL="$fakebin/systemctl" \
    PATH="$fakebin:/usr/bin:/bin" \
    "$dest/usr/local/bin/restart-to-macos" --check >"$output" 2>&1; then
    fail "expected health check to fail without a GUI dialog backend"
  fi

  grep -Fq "Install zenity or kdialog" "$output" || fail "missing GUI guidance in health check output"
  pass "health check fails without gui"
}

test_desktop_and_policy_templates() {
  local dest="$TMP_ROOT/templates"
  "$PROJECT_ROOT/install.sh" --destdir "$dest" --prefix /opt/restart-to-macos >/dev/null
  assert_contains "$dest/opt/restart-to-macos/share/applications/restart-to-macos.desktop" \
    "Exec=/opt/restart-to-macos/bin/restart-to-macos"
  assert_contains "$dest/opt/restart-to-macos/share/polkit-1/actions/io.github.jtbrough.restart-to-macos.policy" \
    "/opt/restart-to-macos/libexec/restart-to-macos-helper"
  pass "template rendering"
}

main() {
  test_manual_install_layout
  test_package_build_layout
  test_no_polkit_install
  test_manual_update_and_uninstall
  test_health_check_success
  test_health_check_fails_without_gui
  test_desktop_and_policy_templates
}

main "$@"
