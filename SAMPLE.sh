#!/bin/sh

set -u
APP=SAMPLE

# CREATE A TEMPORARY DIRECTORY
mkdir -p tmp && cd tmp || exit 1

# DOWNLOADING THE DEPENDENCIES
if test -f ./appimagetool; then
	echo " appimagetool already exists" 1> /dev/null
else
	echo " Downloading appimagetool..."
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
fi
if test -f ./pkg2appimage; then
	echo " pkg2appimage already exists" 1> /dev/null
else
	echo " Downloading pkg2appimage..."
	wget -q https://raw.githubusercontent.com/ivan-hc/AM-application-manager/main/tools/pkg2appimage
fi
chmod a+x ./appimagetool ./pkg2appimage
rm -f ./recipe.yml

# CREATING THE HEAD OF THE RECIPE
echo "app: $APP
binpatch: true

ingredients:

  dist: oldstable
  #script:
    #- COMMAND
  sources:
    - deb http://ftp.debian.org/debian/ oldstable main contrib non-free
    - deb http://security.debian.org/debian-security/ oldstable-security main contrib non-free
    - deb http://ftp.debian.org/debian/ oldstable-updates main contrib non-free
  packages:
    - $APP" > recipe.yml


# DOWNLOAD ALL THE NEEDED PACKAGES AND COMPILE THE APPDIR
./pkg2appimage ./recipe.yml

# VERSION
MAIN_DEB=$(find . -type f -name "$APP\_*.deb" | head -1 | sed 's:.*/::')
if test -f ./"$APP"/"$MAIN_DEB"; then
	ar x ./"$APP"/"$MAIN_DEB" && tar xf ./control.tar.* && rm -f ./control.tar.* ./data.tar.* || exit 1
	VERSION=$(grep Version 0<control | cut -c 10-)
else
	VERSION="test"
fi

# LIBUNIONPRELOAD
rm -f ./"$APP"/"$APP".AppDir/libunionpreload.so
#wget -q https://github.com/project-portable/libunionpreload/releases/download/amd64/libunionpreload.so -O ./"$APP"/"$APP".AppDir/libunionpreload.so && chmod a+x ./"$APP"/"$APP".AppDir/libunionpreload.so || exit 1

# COMPILE SCHEMAS
glib-compile-schemas ./"$APP"/"$APP".AppDir/usr/share/glib-2.0/schemas/ || echo "No ./usr/share/glib-2.0/schemas/"

# CUSTOMIZE THE APPRUN
rm -R -f ./"$APP"/"$APP".AppDir/AppRun
cat >> ./"$APP"/"$APP".AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"

export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"

if test -d "${HERE}"/libunionpreload.so; then export LD_PRELOAD="${HERE}"/libunionpreload.so; fi
export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib64/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
#export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${LD_LIBRARY_PATH}"

if test -d "${HERE}"/usr/lib/python*; then
  PYTHONVERSION=$(find "${HERE}"/usr/lib -type d -name "python*" | head -1 | sed 's:.*/::')
  export PYTHONPATH="${HERE}"/usr/lib/"$PYTHONVERSION"/site-packages/:"${HERE}"/usr/lib/"$PYTHONVERSION"/lib-dynload/:"${PYTHONPATH}"
  export PYTHONHOME="${HERE}"/usr/
fi

export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"

export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"

export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"

QTVER=$(find "${HERE}"/usr/lib -type d -name "qt*" | head -1 | sed 's:.*/::')
if [ -z "$QTVER" ]; then
  export QT_PLUGIN_PATH="${HERE}"/usr/lib/"$QTVER"/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/"$QTVER"/plugins/:"${HERE}"/usr/lib64/"$QTVER"/plugins/:"${HERE}"/lib/"$QTVER"/plugins/:"${HERE}"/lib64/"$QTVER"/plugins/:"${QT_PLUGIN_PATH}"
fi

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
exec ${EXEC} "$@"
EOF
	
# MADE THE APPRUN EXECUTABLE
chmod a+x ./"$APP"/"$APP".AppDir/AppRun
# END OF THE PART RELATED TO THE APPRUN, NOW WE WELL SEE IF EVERYTHING WORKS ----------------------------------------------------------------------

# IMPORT THE LAUNCHER AND THE ICON TO THE APPDIR IF THEY NOT EXIST
if test -f ./"$APP"/"$APP".AppDir/*.desktop; then
	echo "The desktop file exists"
else
	echo "Trying to get the .desktop file"
	cp "./$APP/$APP.AppDir/usr/share/applications/*$(find . -type f -name "*$APP*.desktop" | head -1 | sed 's:.*/::')*" ./"$APP"/"$APP".AppDir/ 2>/dev/null
fi

ICONNAME=$(cat ./"$APP"/"$APP".AppDir/*desktop | grep "Icon=" | head -1 | cut -c 6-)
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/22x22/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/24x24/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/32x32/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/48x48/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/64x64/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/128x128/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/256x256/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/512x512/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/icons/hicolor/scalable/apps/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null
cp ./"$APP"/"$APP".AppDir/usr/share/applications/*"$ICONNAME"* ./"$APP"/"$APP".AppDir/ 2>/dev/null

# UNCOMMENT THE FOLLOWING LINE TO REMOVE FILES IN "METAINFO" IN CASE OF ERRORS WITH "APPSTREAM"


# EXPORT THE APP TO AN APPIMAGE
ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 ./"$APP"/"$APP".AppDir
if ! test -f ./*.AppImage; then
	echo "No AppImage available."; exit 1
fi 
cd .. && mv ./tmp/*.AppImage . && chmod a+x ./*.AppImage || exit 1
