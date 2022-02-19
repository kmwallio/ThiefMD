#!/bin/bash

# Required variables, must be set in rtdata/CMakeLists.txt
PROJECT_NAME="ThiefMD"
PROJECT_SOURCE_DIR=${PROJECTDIR}
GTK_PREFIX=/opt/homebrew/etc/
LOCAL_PREFIX=/opt/homebrew
arch="arm64"
# Formatting
fNormal="$(tput sgr0)"
fBold="$(tput bold)"
# Colors depend upon the user's terminal emulator color scheme - what is readable for you may be not readable for someone else.
fMagenta="$(tput setaf 5)"
fRed="$(tput setaf 1)"

function msg {
    printf "\\n${fBold}-- %s${fNormal}\\n" "${@}"
}

function msgError {
    printf "\\n${fBold}Error:${fNormal}\\n%s\\n" "${@}"
}

function GetDependencies {
    otool -L "$1" | awk 'NR >= 2 && $1 !~ /^(\/usr\/lib|\/System|@executable_path|@rpath)\// { print $1 }'
}

function CheckLink {
    GetDependencies "$1" | while read -r; do
        local dest="${LIB}/$(basename "${REPLY}")"
        test -f "${dest}" || { ditto --arch "${arch}" "${REPLY}" "${dest}"; CheckLink "${dest}"; }
    done
}

function ModifyInstallNames {
    find -E "${CONTENTS}" -type f -regex '.*/(com\.github\.kmwallio\.thiefmd|.*\.(dylib|so))' | while read -r x; do
        msg "Modifying install names: ${x}"
        {
            # id
            if [[ ${x:(-6)} == ".dylib" ]] || [[ f${x:(-3)} == ".so" ]]; then
                install_name_tool -id "${LIB}"/$(basename ${x}) ${x}
            fi
            GetDependencies "${x}" | while read -r y
            do
                install_name_tool -change ${y} "${LIB}"/$(basename ${y}) ${x}
            done
        } | bash -v
    done
}

# Update project version
if [[ -x $(which git) && -d $PROJECT_SOURCE_DIR/.git ]]; then
    ### This section is copied from tools/generateReleaseInfo
    # Get version description.
    # Depending on whether you checked out a branch (dev) or a tag (release),
    # "git describe" will return "5.0-gtk2-2-g12345678" or "5.0-gtk2", respectively.
    gitDescribe="$(git describe --tags --always)"
    
    # Apple requires a numeric version of the form n.n.n
    # https://goo.gl/eWDQv6
    
    # Get number of commits since tagging. This is what gitDescribe uses.
    # Works when checking out branch, tag or commit.
    gitCommitsSinceTag="$(git rev-list --count HEAD --not $(git tag --merged HEAD))"
    
    # Create numeric version.
    # This version is nonsense, either don't use it at all or use it only where you have no other choice, e.g. Inno Setup's VersionInfoVersion.
    # Strip everything after hyphen, e.g. "5.0-gtk2" -> "5.0", "5.1-rc1" -> "5.1" (ergo BS).
    if [[ -z $gitCommitsSinceTag ]]; then
        gitVersionNumericBS="0.0.0"
    else
        gitVersionNumericBS="${gitDescribe%%-*}" # Remove everything after first hyphen.
        gitVersionNumericBS="${gitVersionNumericBS}.${gitCommitsSinceTag}" # Remove everything until after first hyphen: 5.0
    fi
    ### Copy end.
    
    PROJECT_FULL_VERSION="$gitDescribe"
    PROJECT_VERSION="$gitVersionNumericBS"
fi

cat <<__EOS__
PROJECT_NAME:           ${PROJECT_NAME}
PROJECT_VERSION:        ${PROJECT_VERSION}
PROJECT_SOURCE_DIR:     ${PROJECT_SOURCE_DIR}
CMAKE_BUILD_TYPE:       ${CMAKE_BUILD_TYPE}
PROC_BIT_DEPTH:         ${PROC_BIT_DEPTH}
MINIMUM_SYSTEM_VERSION: ${MINIMUM_SYSTEM_VERSION}
GTK_PREFIX:             ${GTK_PREFIX}
PWD:                    ${PWD}
__EOS__

# Retrieve cached values from cmake

#In: CODESIGNID:STRING=Developer ID Application: Doctor Who (1234567890)
#Out: Developer ID Application: Doctor Who (1234567890)
CODESIGNID="Developer ID Application: Miles Wallio (5KVQY6S22A)"

APP="${MESON_INSTALL_PREFIX}"
CONTENTS="${APP}/Contents"
RESOURCES="${CONTENTS}/Resources"
MACOS="${CONTENTS}/MacOS"
LIB="${CONTENTS}/Frameworks"
ETC="${RESOURCES}/etc"
EXECUTABLE="${MACOS}/com.github.kmwallio.thiefmd"
GDK_PREFIX="${LOCAL_PREFIX}/"
BIN_DIR="${CONTENTS}/bin"

msg "Creating bundle container:"
install -d "${RESOURCES}"
install -d "${MACOS}"
install -d "${LIB}"
install -d "${ETC}"
install -d "${BIN_DIR}"

msg "Copying binary executable files."
cp "${PROJECTDIR}/build/com.github.kmwallio.thiefmd" "${MACOS}/"

echo "\n--------\n" >> "${RESOURCES}/AboutThisBuild.txt"
echo "Bundle system: $(sysctl -n machdep.cpu.brand_string)" >> "${RESOURCES}/AboutThisBuild.txt"
echo "Bundle OS:     $(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -mrs)" >> "${RESOURCES}/AboutThisBuild.txt"
echo "Bundle date:   $(date -Ru) UTC" >> "${RESOURCES}/AboutThisBuild.txt"
echo "Bundle epoch:  $(date +%s)" >> "${RESOURCES}/AboutThisBuild.txt"
echo "Bundle UUID:   $(uuidgen|tr 'A-Z' 'a-z')" >> "${RESOURCES}/AboutThisBuild.txt"

msg "Copying dependencies from ${GTK_PREFIX}."
CheckLink "${EXECUTABLE}"

# dylib install names
ModifyInstallNames

# Copy libz into the app bundle
ditto ${LOCAL_PREFIX}/lib/libz.1.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libglib-2.0.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgee-0.8.2.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgobject-2.0.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgio-2.0.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgtk-3.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libclutter-1.0.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libjson-glib-1.0.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgtksourceview-4.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libgtkspell3-3.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/liblink-grammar.5.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libarchive.13.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libhandy-1.0.dylib "${CONTENTS}/Frameworks"
ditto ${LOCAL_PREFIX}/lib/libpango-1.0.0.dylib "${CONTENTS}/Frameworks"

# Prepare GTK+3 installation
msg "Copying configuration files from ${GTK_PREFIX}:"
cp -RL {"${GDK_PREFIX}/lib","${LIB}"}/gdk-pixbuf-2.0
msg "Copying library modules from ${GTK_PREFIX}:"
cp -RL {"${GDK_PREFIX}/lib","${LIB}"}/gdk-pixbuf-2.0
ditto --arch "${arch}" {"${GTK_PREFIX}/lib","${LIB}"}/gtk-3.0
msg "Removing static libraries and cache files:"
find -E "${LIB}" -type f -regex '.*\.(a|la|cache)$' | while read -r; do rm "${REPLY}"; done

# Make Frameworks folder flat
msg "Flattening the Frameworks folder"
cp -RL "${LIB}"/gdk-pixbuf-2.0/2*/loaders/* "${LIB}"
cp "${LIB}"/gtk-3.0/3*/immodules/*.{dylib,so} "${LIB}"
yes | rm -r "${LIB}/gtk-3.0"
yes | rm -r "${LIB}/gdk-pixbuf-2.0"

# GTK+3 themes
msg "Copy GTK+3 theme and icon resources:"
ditto {"${LOCAL_PREFIX}","${RESOURCES}"}/share/themes/Mac/gtk-3.0/gtk-keys.css
ditto {"${LOCAL_PREFIX}","${RESOURCES}"}/share/themes/Default/gtk-3.0/gtk-keys.css
cp -RL {"${LOCAL_PREFIX}/share/themes/Adwaita","${LIB}"}/share/themes/Adwaita
cp -RL {"${LOCAL_PREFIX}/share/themes/Adwaita-dark","${LIB}"}/share/themes/Adwaita-dark

# Adwaita icons
msg "Copy Adwaita icons"
iconfolders=("16x16/actions" "16x16/devices" "16x16/mimetypes" "16x16/places" "16x16/status" "16x16/ui" "48x48/devices")
for f in "${iconfolders[@]}"; do
    mkdir -p ${RESOURCES}/share/icons/Adwaita/${f}
    cp -RL ${LOCAL_PREFIX}/share/icons/Adwaita/${f}/* "${RESOURCES}"/share/icons/Adwaita/${f}
done
cp -RL {"${LOCAL_PREFIX}","${RESOURCES}"}/share/icons/Adwaita/index.theme
"${LOCAL_PREFIX}/bin/gtk-update-icon-cache" "${RESOURCES}/share/icons/Adwaita" || "${LOCAL_PREFIX}/bin/gtk-update-icon-cache-3.0" "${RESOURCES}/share/icons/Adwaita"
cp -RL "${LOCAL_PREFIX}/share/icons/hicolor" "${RESOURCES}/share/icons/hicolor"

cp /opt/homebrew/bin/gdbus "${BIN_DIR}/"
cp /opt/homebrew/bin/gdk-pixbuf-query-loaders "${BIN_DIR}/"

# fix libfreetype install name
for lib in "${LIB}"/*; do
    install_name_tool -change libfreetype.6.dylib "${LIB}"/libfreetype.6.dylib "${lib}"
done

# hopes and dreams...
for lib in "${LIB}"/*; do
    for lib2 in "${LIB}"/*; do
        install_name_tool -change ${lib} "${LIB}"/"${lib}" "${lib2}"
    done
done

# Build GTK3 pixbuf loaders & immodules database
msg "Build GTK3 databases:"
"${LOCAL_PREFIX}"/bin/gdk-pixbuf-query-loaders "${LIB}"/libpixbufloader-*.so > "${ETC}"/gtk-3.0/gdk-pixbuf.loaders
"${LOCAL_PREFIX}"/bin/gtk-query-immodules-3.0 "${LIB}"/im-* > "${ETC}"/gtk-3.0/gtk.immodules || "${LOCAL_PREFIX}"/bin/gtk-query-immodules "${LIB}"/im-* > "${ETC}"/gtk-3.0/gtk.immodules
sed -i.bak -e "s|${PWD}/${PROJECT_NAME}.app/Contents/|/Applications/${PROJECT_NAME}.app/Contents/|" "${ETC}"/gtk-3.0/gdk-pixbuf.loaders "${ETC}/gtk-3.0/gtk.immodules"
sed -i.bak -e "s|${LOCAL_PREFIX}/share/|/Applications/${PROJECT_NAME}.app/Contents/Resources/share/|" "${ETC}"/gtk-3.0/gtk.immodules
sed -i.bak -e "s|${LOCAL_PREFIX}/|/Applications/${PROJECT_NAME}.app/Contents/Frameworks/|" "${ETC}"/gtk-3.0/gtk.immodules
rm "${ETC}"/*.bak

# Install names
ModifyInstallNames

# Mime directory
msg "Copying shared files from ${GTK_PREFIX}:"
ditto {"${LOCAL_PREFIX}","${RESOURCES}"}/share/mime

# App bundle resources
update-mime-database -V  "${RESOURCES}/share/mime"
cp -RL "${LOCAL_PREFIX}/share/locale" "${RESOURCES}/share/locale"

msg "Build glib database:"
mkdir -p ${RESOURCES}/share/glib-2.0
cp -LR {"${LOCAL_PREFIX}","${RESOURCES}"}/share/glib-2.0/schemas
"${LOCAL_PREFIX}/bin/glib-compile-schemas" "${RESOURCES}/share/glib-2.0/schemas"

# Append an LC_RPATH
msg "Registering @rpath into the main executable."
install_name_tool -add_rpath "${LIB}" "${EXECUTABLE}"

ModifyInstallNames

# fix @rpath in Frameworks
msg "Registering @rpath in Frameworks folder."
for frameworklibs in "${LIB}"/*{dylib,so,cli}; do
    install_name_tool -delete_rpath ${LOCAL_PREFIX}/lib "${frameworklibs}"
    install_name_tool -add_rpath "${LIB}" "${frameworklibs}"
done

msg "Registering @rpath in Bins folder."
for bins in "${BIN_DIR}"/*; do
    install_name_tool -delete_rpath ${LOCAL_PREFIX}/lib "${bins}"
    install_name_tool -add_rpath "${LIB}" "${bins}"
    for lib2 in "${LIB}"/*; do
        install_name_tool -change ${lib} "${LIB}"/"${lib}" "${bins}"
    done
done

install_name_tool -add_rpath "${LIB}" "${EXECUTABLE}"-cli
ditto "${EXECUTABLE}" "${APP}"/..

# Codesign the app
if [[ -n $CODESIGNID ]]; then
    msg "Codesigning Application."
    codesign --force --deep --timestamp --strict -v -s "${CODESIGNID}" -i com.github.kmwallio.thiefmd -o runtime "${APP}"
    pushd $LIB
    ls | xargs codesign -f --deep -s "${CODESIGNID}"
    popd
    spctl -a -vvvv "${APP}"
fi

msg "Finishing build:"
echo "Script complete."
