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

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_CODE=\"${APP_CODE}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "VERSION_REPO_NAME=\"${VERSION_REPO_NAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      apply_patch "${file}"
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    apply_patch "${file}"
  fi
done

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

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  npm ci && break
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc

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
setpath "product" "licenseUrl" "https://github.com/${GH_REPO_PATH}/blob/master/LICENSE"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/${GH_REPO_PATH}/issues/new"
setpath "product" "requestFeatureUrl" "https://go.microsoft.com/fwlink/?LinkID=533482"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://go.microsoft.com/fwlink/?LinkID=533687"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/${ORG_NAME}/${VERSION_REPO_NAME}/refs/heads/master"
  setpath "product" "downloadUrl" "https://github.com/${GH_REPO_PATH}/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "${APP_NAME} - Insiders"
  setpath "product" "nameLong" "${APP_NAME} - Insiders"
  setpath "product" "applicationName" "${BINARY_NAME}-insiders"
  setpath "product" "dataFolderName" ".${BINARY_NAME}-insiders"
  setpath "product" "linuxIconName" "${BINARY_NAME}-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "${BINARY_NAME}-insiders"
  setpath "product" "serverApplicationName" "${BINARY_NAME}-server-insiders"
  setpath "product" "serverDataFolderName" ".${BINARY_NAME}-server-insiders"
  setpath "product" "darwinBundleIdentifier" "com.${BINARY_NAME}.${APP_CODE}Insiders"
  setpath "product" "win32AppUserModelId" "${APP_NAME}.${APP_CODE}Insiders"
  setpath "product" "win32DirName" "${APP_NAME} Insiders"
  setpath "product" "win32MutexName" "${BINARY_NAME}insiders"
  setpath "product" "win32NameVersion" "${APP_NAME} Insiders"
  setpath "product" "win32RegValueName" "${APP_CODE}Insiders"
  setpath "product" "win32ShellNameShort" "${APP_NAME} Insiders"
  setpath "product" "win32AppId" "{{D804CEAC-95DD-4154-A344-15C78142E21E}"
  setpath "product" "win32x64AppId" "{{5E9295B9-8893-4F4F-8C9A-08A91E45C46F}"
  setpath "product" "win32arm64AppId" "{{152B68E8-134C-49CE-B1A3-821DF542546C}"
  setpath "product" "win32UserAppId" "{{84EF8F42-AF46-4C65-AFF4-E19722A51D40}"
  setpath "product" "win32x64UserAppId" "{{CABB2501-17B9-4C3E-93E7-14A61B3924E5}"
  setpath "product" "win32arm64UserAppId" "{{85063C29-028A-4476-8EDB-3A2689FB6DAC}"
else
  setpath "product" "nameShort" "${APP_NAME}"
  setpath "product" "nameLong" "${APP_NAME}"
  setpath "product" "applicationName" "${BINARY_NAME}"
  setpath "product" "linuxIconName" "${BINARY_NAME}"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "${BINARY_NAME}"
  setpath "product" "serverApplicationName" "${BINARY_NAME}-server"
  setpath "product" "serverDataFolderName" ".${BINARY_NAME}-server"
  setpath "product" "darwinBundleIdentifier" "com.${BINARY_NAME}"
  setpath "product" "win32AppUserModelId" "${APP_NAME}.${APP_NAME}"
  setpath "product" "win32DirName" "${APP_NAME}"
  setpath "product" "win32MutexName" "${BINARY_NAME}"
  setpath "product" "win32NameVersion" "${APP_NAME}"
  setpath "product" "win32RegValueName" "${APP_NAME}"
  setpath "product" "win32ShellNameShort" "${APP_NAME}"
  setpath "product" "win32AppId" "{{06323B58-1C22-472C-80EB-BC05A7382936}"
  setpath "product" "win32x64AppId" "{{2DE2D14E-7BB6-427F-9C5F-36629BDAA2B2}"
  setpath "product" "win32arm64AppId" "{{066BB6CA-A580-47AD-BAD8-83AD4ED74BDD}"
  setpath "product" "win32UserAppId" "{{8BB05100-60D0-4338-87F1-60DD60C6E604}"
  setpath "product" "win32x64UserAppId" "{{2CB7714B-6380-4F8C-8FB1-1667CF40D65A}"
  setpath "product" "win32arm64UserAppId" "{{6448FFF7-D0FB-4A8C-903B-A0F0E35A0C0D}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

replace "s|Microsoft Corporation|${APP_NAME}|" package.json

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace "s|Microsoft Corporation|${APP_NAME}|" build/lib/electron.js
replace "s|Microsoft Corporation|${APP_NAME}|" build/lib/electron.ts
replace "s|([0-9]) Microsoft|\1 ${APP_NAME}|" build/lib/electron.js
replace "s|([0-9]) Microsoft|\1 ${APP_NAME}|" build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to ${BINARY_NAME}
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/${BINARY_NAME}-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/${BINARY_NAME}/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://${BINARY_NAME}.com/img/${BINARY_NAME}.png|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/code.appdata.xml

  # control.template
  sed -i "s|Microsoft Corporation <vscode-linux@microsoft.com>|${APP_NAME} Team https://github.com/${GH_REPO_PATH}/graphs/contributors|"  resources/linux/debian/control.template
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/debian/control.template

  # code.spec.template
  sed -i "s|Microsoft Corporation|${APP_NAME} Team|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code Team <vscode-linux@microsoft.com>|${APP_NAME} Team https://github.com/${GH_REPO_PATH}/graphs/contributors|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code|${APP_NAME}|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i "s|Visual Studio Code|${APP_NAME}|"  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  # sed -i 's|https://code.visualstudio.com|https://vscodium.com|' build/win32/code.iss
  # sed -i 's|Microsoft Corporation|VSCodium|' build/win32/code.iss
fi

cd ..
