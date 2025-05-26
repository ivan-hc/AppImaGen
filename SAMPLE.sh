#!/bin/sh

APP=SAMPLE
APPIMAGE_DIR="$APP/$APP.AppDir"

export ARCH="x86_64"

# DEPENDENCIES

dependencies="ar tar unzip"
for d in $dependencies; do
	if ! command -v "$d" 1>/dev/null; then
		echo "ERROR: missing command \"d\", install the above and retry" && exit 1
	fi
done

_appimagetool() {
	if ! command -v appimagetool 1>/dev/null; then
		[ ! -f ./appimagetool ] && echo " Downloading appimagetool..." && curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage && chmod a+x ./appimagetool
		./appimagetool "$@"
	else
		appimagetool "$@"
	fi
}

# CREATE DIRECTORIES
mkdir -p "tmp/$APPIMAGE_DIR" && cd tmp || exit 1

################################################################################################################################################################
#				BUILD
################################################################################################################################################################

# This entire section is geared towards compiling via pkg2appimage, but you can replace everything with a different build type
# This is the 1eceb30 build of pkg2appimage, converted to the new runtime that does not require libfuse2 and published in the "AM" repository

_pkg2appimage() {
	if ! command -v pkg2appimage 1>/dev/null; then
		[ ! -f ./pkg2appimage ] && echo " Downloading pkg2appimage..." && curl -#Lo pkg2appimage https://github.com/ivan-hc/AM/raw/main/tools/pkg2appimage && chmod a+x ./pkg2appimage
		./pkg2appimage "$@"
	else
		pkg2appimage "$@"
	fi
}

# RECIPE
distro="debian"
codename="oldstable"
packages=""
ppas=""

debian_sources="
    - deb http://ftp.debian.org/debian/ $codename main contrib non-free
    - deb http://security.debian.org/debian-security/ $codename-security main contrib non-free
    - deb http://ftp.debian.org/debian/ $codename-updates main contrib non-free
    "

ubuntu_sources="
    - deb http://archive.ubuntu.com/ubuntu/ $codename main universe restricted multiverse
    - deb http://archive.ubuntu.com/ubuntu $codename-security main universe restricted multiverse
    - deb http://archive.ubuntu.com/ubuntu/ $codename-updates main universe restricted multiverse
    "

if [ "$distro" = debian ]; then
	sources="$debian_sources"
else
	sources="$ubuntu_sources"
fi

recipe="app: $APP
binpatch: true

ingredients:

  dist: $codename
  #script:
    #- COMMAND
  sources:$sources"

echo "$recipe" > recipe.yml

if [ -n "$ppas" ]; then
	echo "  ppas:" >> recipe.yml
	for p in $ppas; do
		echo "    - $p" >> recipe.yml
	done
fi

echo "  packages:
    - $APP" >> recipe.yml

if [ -n "$packages" ]; then
	for p in $packages; do
		echo "    - $p" >> recipe.yml
	done
fi

# DOWNLOAD ALL THE NEEDED PACKAGES AND COMPILE THE APPDIR
_pkg2appimage ./recipe.yml

# COMPILE SCHEMAS
glib-compile-schemas "$APPIMAGE_DIR"/usr/share/glib-2.0/schemas/ || echo "No ./usr/share/glib-2.0/schemas/"

################################################################################################################################################################
#				COMMON
################################################################################################################################################################

# APPRUN
rm -f "$APPIMAGE_DIR"/AppRun
cat >> "$APPIMAGE_DIR"/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"

export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"

export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib64/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
#export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${LD_LIBRARY_PATH}" # Uncomment to use system libraries

export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"

if test -d "${HERE}"/usr/lib/python*; then
  PYTHONVERSION=$(find "${HERE}"/usr/lib -type d -name "python*" | head -1 | sed 's:.*/::')
  export PYTHONPATH="${HERE}"/usr/lib/"$PYTHONVERSION"/site-packages/:"${HERE}"/usr/lib/"$PYTHONVERSION"/lib-dynload/:"${PYTHONPATH}"
  export PYTHONHOME="${HERE}"/usr/
fi

export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"

export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"

QTVER=$(find "${HERE}"/usr/lib -type d -name "qt*" | head -1 | sed 's:.*/::')
if [ -z "$QTVER" ]; then
  export QT_PLUGIN_PATH="${HERE}"/usr/lib/"$QTVER"/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/"$QTVER"/plugins/:"${HERE}"/usr/lib64/"$QTVER"/plugins/:"${HERE}"/lib/"$QTVER"/plugins/:"${HERE}"/lib64/"$QTVER"/plugins/:"${QT_PLUGIN_PATH}"
fi

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
exec ${EXEC} "$@"
EOF
chmod a+x "$APPIMAGE_DIR"/AppRun

# VERSION
MAIN_DEB=$(find . -type f -name "$APP\_*.deb" | head -1 | sed 's:.*/::')
if test -f "$APP"/"$MAIN_DEB"; then
	ar x "$APP"/"$MAIN_DEB" && tar xf ./control.tar.* && rm -f ./control.tar.* ./data.tar.* || exit 1
	PKG_VERSION=$(grep Version 0<control | cut -c 10-)
else
	PKG_VERSION="test"
fi

# LAUNCHER
if ! test -f "$APPIMAGE_DIR"/*.desktop; then
	echo "Trying to get the .desktop file"
	cp "./$APP/$APP.AppDir/usr/share/applications/*$(find . -type f -name "*$APP*.desktop" | head -1 | sed 's:.*/::')*" "$APPIMAGE_DIR"/ 2>/dev/null
fi

# ICON
ICONNAME=$(cat "$APPIMAGE_DIR"/*desktop | grep "Icon=" | head -1 | cut -c 6- | sed 's/.png$//g; s/.svg$//g')
ICON=$(find "$APPIMAGE_DIR" -type f -name *"$ICONNAME".png -o -name *"$ICONNAME".svg ! -type l | sort -V | tail -1)
cp -r "$ICON" "$APPIMAGE_DIR"/ 2>/dev/null

# CONVERT THE APPDIR TO AN APPIMAGE

[ -z "$GITHUB_REPOSITORY_OWNER" ] && GITHUB_REPOSITORY_OWNER="ivan-hc"
REPO_NAME="$APP-appimage"
TAG_NAME="latest"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO_NAME|$TAG_NAME|*$ARCH.AppImage.zsync"
VERSION="$PKG_VERSION" _appimagetool -u "$UPINFO" -n "$APPIMAGE_DIR" 2>&1
if ! test -f ./*.AppImage; then
	echo "No AppImage available."; exit 1
fi
cd .. && mv ./tmp/*.AppImage* . && chmod a+x ./*.AppImage || exit 1
