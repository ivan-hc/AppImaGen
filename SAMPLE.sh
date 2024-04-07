#!/usr/bin/env bash

APP=SAMPLE

# CREATE A TEMPORARY DIRECTORY
mkdir -p tmp
cd tmp || return

# DOWNLOADING THE DEPENDENCIES
if test -f ./appimagetool; then
	echo " appimagetool already exists" 1> /dev/null
else
	echo " Downloading appimagetool..."
	wget -q "$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | grep -v zsync | grep -i continuous | grep -i appimagetool | grep -i x86_64 | grep browser_download_url | cut -d '"' -f 4 | head -1)" -O appimagetool
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
  sources:
    - deb http://ftp.debian.org/debian/ oldstable main contrib non-free
    - deb http://security.debian.org/debian-security/ oldstable-security main contrib non-free
    - deb http://ftp.debian.org/debian/ oldstable-updates main contrib non-free
  packages:
    - $APP" >> recipe.yml


# DOWNLOAD ALL THE NEEDED PACKAGES AND COMPILE THE APPDIR
./pkg2appimage ./recipe.yml

# LIBUNIONPRELOAD
#wget https://github.com/project-portable/libunionpreload/releases/download/amd64/libunionpreload.so
#chmod a+x libunionpreload.so
#mv ./libunionpreload.so ./$APP/$APP.AppDir/

# COMPILE SCHEMAS
glib-compile-schemas ./$APP/$APP.AppDir/usr/share/glib-2.0/schemas/ || echo "No ./usr/share/glib-2.0/schemas/"

# CUSTOMIZE THE APPRUN
rm -R -f ./$APP/$APP.AppDir/AppRun
cat >> ./$APP/$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD=/:"${HERE}"
#export LD_PRELOAD="${HERE}"/libunionpreload.so
export LD_LIBRARY_PATH=/lib/:/lib64/:/lib/x86_64-linux-gnu/:/usr/lib/:"${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${HERE}"/bin/:"${HERE}"/sbin/:"${PATH}"
export PYTHONPATH="${HERE}"/usr/share/pyshared/:"${HERE}"/usr/lib/python*/:"${PYTHONPATH}"
export PYTHONHOME="${HERE}"/usr/:"${HERE}"/usr/lib/python*/
export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"
export PERLLIB="${HERE}"/usr/share/perl5/:"${HERE}"/usr/lib/perl5/:"${PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}"/usr/share/glib-2.0/schemas/:"${GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}"/usr/lib/qt4/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt4/plugins/:"${HERE}"/usr/lib32/qt4/plugins/:"${HERE}"/usr/lib64/qt4/plugins/:"${HERE}"/usr/lib/qt5/plugins/:"${HERE}"/usr/lib/i386-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib/x86_64-linux-gnu/qt5/plugins/:"${HERE}"/usr/lib32/qt5/plugins/:"${HERE}"/usr/lib64/qt5/plugins/:"${QT_PLUGIN_PATH}"
EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
exec ${EXEC} "$@"
EOF
	
# MADE THE APPRUN EXECUTABLE
chmod a+x ./$APP/$APP.AppDir/AppRun
# END OF THE PART RELATED TO THE APPRUN, NOW WE WELL SEE IF EVERYTHING WORKS ----------------------------------------------------------------------

# IMPORT THE LAUNCHER AND THE ICON TO THE APPDIR IF THEY NOT EXIST
if test -f ./$APP/$APP.AppDir/*.desktop; then
	echo "The desktop file exists"
else
	echo "Trying to get the .desktop file"
	cp "./$APP/$APP.AppDir/usr/share/applications/*$(ls . | grep -i $APP | cut -c -4)*desktop" ./$APP/$APP.AppDir/ 2>/dev/null
fi

ICONNAME=$(cat ./$APP/$APP.AppDir/*desktop | grep "Icon=" | head -1 | cut -c 6-)
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/22x22/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/24x24/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/32x32/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/48x48/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/64x64/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/128x128/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/256x256/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/512x512/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/icons/hicolor/scalable/apps/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null
cp ./$APP/$APP.AppDir/usr/share/applications/*"$ICONNAME"* ./$APP/$APP.AppDir/ 2>/dev/null

# UNCOMMENT THE FOLLOWING LINE TO REMOVE FILES IN "METAINFO" IN CASE OF ERRORS WITH "APPSTREAM"
#rm -R -f ./$APP/$APP.AppDir/usr/share/metainfo/*

# EXPORT THE APP TO AN APPIMAGE
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP/$APP.AppDir
cd ..
mv ./tmp/*.AppImage .
chmod a+x ./*.AppImage
