#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying user patch: "${file}";
    if ! git apply --ignore-whitespace "${file}"; then
      echo failed to apply patch "${file}" >&2
      exit 1
    fi
  fi
done

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo failed to apply patch "${file}" >&2
        exit 1
      fi
    fi
  done
fi

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
fi

for i in {1..5}; do # try 5 times
  npm ci && break
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://go.microsoft.com/fwlink/?LinkID=533484#vscode"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item", "extensionUrlTemplate": "https://open-vsx.org/vscode/gallery/{publisher}/{name}/latest"}'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/XunlongCode/xunlongcode/blob/master/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/XunlongCode/xunlongcode/issues/new"
setpath "product" "requestFeatureUrl" "https://go.microsoft.com/fwlink/?LinkID=533482"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://go.microsoft.com/fwlink/?LinkID=533687"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/XunlongCode/versions/refs/heads/master"
  setpath "product" "downloadUrl" "https://github.com/XunlongCode/xunlongcode/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "XunlongCode - Insiders"
  setpath "product" "nameLong" "XunlongCode - Insiders"
  setpath "product" "applicationName" "xlcode-insiders"
  setpath "product" "dataFolderName" ".xunlongcode-insiders"
  setpath "product" "linuxIconName" "vscodium-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "xunlongcode-insiders"
  setpath "product" "serverApplicationName" "xlcode-server-insiders"
  setpath "product" "serverDataFolderName" ".xunlongcode-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.xunlongcode.XunlongCodeInsiders"
  setpath "product" "win32AppUserModelId" "XunlongCode.XunlongCodeInsiders"
  setpath "product" "win32DirName" "XunlongCode Insiders"
  setpath "product" "win32MutexName" "xunlongcodeinsiders"
  setpath "product" "win32NameVersion" "XunlongCode Insiders"
  setpath "product" "win32RegValueName" "XunlongCodeInsiders"
  setpath "product" "win32ShellNameShort" "XunlongCode Insiders"
  setpath "product" "win32AppId" "{{FE8723BA-8C4D-4060-BEC6-FFE4E0093702}"
  setpath "product" "win32x64AppId" "{{F6A63B1A-5338-4063-B7C9-14EA3F543A0E}"
  setpath "product" "win32arm64AppId" "{{BF9C8B4D-9C7D-4CDC-AA1F-3FD05EE460ED}"
  setpath "product" "win32UserAppId" "{{62AC363A-0FF5-4AC3-B697-207E32CDEC36}"
  setpath "product" "win32x64UserAppId" "{{4325731C-F8B4-47BD-9A19-A3AE45CCD8C7}"
  setpath "product" "win32arm64UserAppId" "{{32CFC73E-F826-412A-8AE3-B11631D1BCF3}"
else
  setpath "product" "nameShort" "XunlongCode"
  setpath "product" "nameLong" "XunlongCode"
  setpath "product" "applicationName" "xlcode"
  setpath "product" "linuxIconName" "vscodium"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "xunlongcode"
  setpath "product" "serverApplicationName" "xlcode-server"
  setpath "product" "serverDataFolderName" ".xunlongcode-server"
  setpath "product" "darwinBundleIdentifier" "com.xunlongcode"
  setpath "product" "win32AppUserModelId" "XunlongCode.XunlongCode"
  setpath "product" "win32DirName" "XunlongCode"
  setpath "product" "win32MutexName" "xunlongcode"
  setpath "product" "win32NameVersion" "XunlongCode"
  setpath "product" "win32RegValueName" "XunlongCode"
  setpath "product" "win32ShellNameShort" "XunlongCode"
  setpath "product" "win32AppId" "{{FACD9FA4-8E63-4D96-8870-1EC172C95190}"
  setpath "product" "win32x64AppId" "{{9AE64A1C-48C9-4D21-8DBB-1BEB10D10E0A}"
  setpath "product" "win32arm64AppId" "{{C073A293-5397-48A8-8E8F-116DC852F90F}"
  setpath "product" "win32UserAppId" "{{CCB9E163-9601-4E71-87FE-9B27883EE3C2}"
  setpath "product" "win32x64UserAppId" "{{B94B0A07-78F2-435D-9748-DCC92DC158F2}"
  setpath "product" "win32arm64UserAppId" "{{5BDA8CEA-AD0E-4F3D-B485-80F72FDDE24F}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

replace 's|Microsoft Corporation|XunlongCode|' package.json

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|XunlongCode|' build/lib/electron.js
replace 's|Microsoft Corporation|XunlongCode|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 XunlongCode|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 XunlongCode|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to xunlongcode
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/xlcode-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/xlcode/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|XunlongCode|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/XunlongCode/xunlongcode#download-install|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/xunlongcode.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|XunlongCode Team https://github.com/XunlongCode/xunlongcode/graphs/contributors|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|XunlongCode|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/XunlongCode/xunlongcode#download-install|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|XunlongCode Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|XunlongCode Team https://github.com/XunlongCode/xunlongcode/graphs/contributors|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|XunlongCode|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://github.com/XunlongCode/xunlongcode#download-install|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|XunlongCode|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|XunlongCode|' build/win32/code.iss
fi

cd ..
