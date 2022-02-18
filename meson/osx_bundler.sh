#!/bin/bash

PROJECTDIR="$( cd "$(dirname "$0")/../" ; pwd -P )"
APP="ThiefMD.app"
APP_TOP_DIR=${MESON_INSTALL_PREFIX}
APP_CON_DIR=$APP_TOP_DIR/Contents
APP_RES_DIR=$APP_CON_DIR/Resources
APP_EXE_DIR=$APP_CON_DIR/bin
APP_ETC_DIR=$APP_CON_DIR/etc
APP_LIB_DIR=$APP_CON_DIR/Frameworks
APP_SHARE_DIR=$APP_CON_DIR/share
CONTENTS=$APP_CON_DIR
LIB="${APP_LIB_DIR}"
ETC="${APP_EXE_DIR}"

function lib_dependency_copy
{
  # This function use otool to analyze library dependency.
  # then copy the dependency libraries to destination path

  local target=$1
  local folder=$2

  libraries="$(otool -L $target | grep "/*.*dylib" -o | xargs)"
  echo -n "Looking at $target"
  for lib in $libraries; do
    if [[ '/usr/lib/' != ${lib:0:9} && '/System/Library/' != ${lib:0:16} ]]; then
      cp $lib $folder
    fi  
  done
}

function lib_dependency_analyze
{
  # This function use otool to analyze library directory.
  # then copy the dependency libraries to destination path

  local library_dir=$1
  local targets_dir=$2

  libraries="$(find $library_dir -name \*.dylib -o -name \*.so -type f)"
  for lib in $libraries; do
      lib_dependency_copy $lib $targets_dir
  done
}

function lib_change_path
{
  # This is a simple wrapper around install_name_tool to reduce the
  # number of arguments (like $source does not have to be provided
  # here as it can be deducted from $target).
  # Also, the requested change can be applied to multipe binaries
  # at once since 2-n arguments can be supplied.

  local target=$1         # new path to dynamically linked library
  local binaries=${*:2}   # binaries to modify

  local source_lib=${target##*/}   # get library filename from target location

  for binary in $binaries; do   # won't work with spaces in paths
    if [[ $binary == *.so ]] || [[ $binary == *.dylib ]]; then
      lib_reset_id $binary
    fi
    local source=$(otool -L $binary | grep $source_lib | awk '{ print $1 }')
    install_name_tool -change $source $target $binary
  done
}

function lib_change_paths
{
  # This is a slightly more advanced wrapper around install_name_tool.
  # Given a directory $lib_dir that contains the libraries, all libraries
  # linked in $binary can be changed at once to a specified $target path.

  local target=$1         # new path to dynamically linked library
  local lib_dir=$2
  local binaries=${*:3}

  for binary in $binaries; do
    if [[ $binary == *.so ]] || [[ $binary == *.dylib ]]; then
      lib_reset_id $binary
    fi
    for linked_lib in $(otool -L $binary | tail -n +2 | awk '{ print $1 }'); do
      if [ "$(basename $binary)" != "$(basename $linked_lib)" ] &&
         [ -f $lib_dir/$(basename $linked_lib) ]; then
        lib_change_path $target/$(basename $linked_lib) $binary
      fi
    done
  done
}

function lib_change_siblings
{
  # This is a slightly more advanced wrapper around install_name_tool.
  # All libraries inside a given $dir that are linked to libraries present
  # in that $dir can be automatically adjusted.

  local dir=$1
  local target=$2

  for lib in $dir/*.dylib; do
    lib_reset_id $lib
    for linked_lib in $(otool -L $lib | tail -n +2 | awk '{ print $1 }'); do
      if [ "$(basename $lib)" != "$(basename $linked_lib)" ] &&
         [ -f $dir/$(basename $linked_lib) ]; then
        lib_change_path $target/$(basename $linked_lib) $lib
      fi
    done
  done

  if ls $dir/*.so 1> /dev/null 2>&1; then
    for lib in $dir/*.so; do
      lib_reset_id $lib
      for linked_lib in $(otool -L $lib | tail -n +2 | awk '{ print $1 }'); do
        if [ "$(basename $lib)" != "$(basename $linked_lib)" ] &&
          [ -f $dir/$(basename $linked_lib) ]; then
          lib_change_path $target/$(basename $linked_lib) $lib
        fi
      done
    done  
  fi
}

function lib_reset_id
{
  local lib=$1

  install_name_tool -id $(basename $lib) $lib
}

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

echo -n "Copy app dependency library......"
mkdir -p "${APP_CON_DIR}/MacOs/"
mkdir -p ${APP_EXE_DIR}
mkdir -p ${APP_LIB_DIR}
mkdir -p ${APP_EXE_DIR}
mkdir -p "${APP_SHARE_DIR}/themes"
mkdir -p "${APP_SHARE_DIR}/glib-2.0/schemas"
mkdir -p "${APP_SHARE_DIR}/icons/hicolor/scalable/apps"
lib_dependency_copy ${PROJECTDIR}/build/com.github.kmwallio.thiefmd "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libglib-2.0.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgee-0.8.2.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgobject-2.0.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgio-2.0.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgtk-3.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libclutter-1.0.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libjson-glib-1.0.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgtksourceview-4.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libgtkspell3-3.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/liblink-grammar.5.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libarchive.13.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libhandy-1.0.dylib "${APP_LIB_DIR}"
lib_dependency_copy ${MESON_INSTALL_PREFIX}/bin/libpango-1.0.0.dylib "${APP_LIB_DIR}"
cp -f "${PROJECTDIR}/data/icons/128/com.github.kmwallio.thiefmd.svg" "${TARGETDIR}/share/icons/hicolor/scalable/apps"
cp -f "${PROJECTDIR}/build/com.github.kmwallio.thiefmd" "${APP_EXE_DIR}/com.github.kmwallio.thiefmd"

echo -n "Copy GDBus/Helper and dependencies......"
cp /opt/homebrew/bin/gdbus "${APP_EXE_DIR}/"
cp /opt/homebrew/bin/gdk-pixbuf-query-loaders "${APP_EXE_DIR}/"
lib_dependency_copy ${APP_EXE_DIR}/gdbus "${APP_LIB_DIR}"
lib_dependency_copy ${APP_EXE_DIR}/gdk-pixbuf-query-loaders "${APP_LIB_DIR}"
echo -n "[done]"

# copy GTK runtime dependencies resource
echo -n "Copy GTK runtime resource......"
cp -rf /opt/homebrew/lib/gio "${APP_LIB_DIR}"
cp -rf /opt/homebrew/lib/gtk-3.0 "${APP_LIB_DIR}"
cp -rf /opt/homebrew/lib/gdk-pixbuf-2.0 "${APP_LIB_DIR}"
cp -rf /opt/homebrew/lib/girepository-1.0 "${APP_LIB_DIR}"
cp -rf /opt/homebrew/lib/libgda-5.0 "${APP_LIB_DIR}"
cp -rf /opt/homebrew/etc/gtk-3.0 "${APP_ETC_DIR}"
# Avoid override the latest locale file
cp -r /opt/homebrew/share/locale "${APP_SHARE_DIR}"
cp -rf /opt/homebrew/share/icons "${APP_SHARE_DIR}"
cp -rf /opt/homebrew/share/fontconfig "${APP_SHARE_DIR}"
cp -rf /opt/homebrew/share/themes/Mac "${APP_SHARE_DIR}/themes/"
cp -rf /opt/homebrew/share/themes/Default "${APP_SHARE_DIR}/themes/"
cp -rf /opt/homebrew/share/themes/Adwaita "${APP_SHARE_DIR}/themes/"
cp -rf /opt/homebrew/share/themes/Adwaita-dark "${APP_SHARE_DIR}/themes/"
cp -rf /opt/homebrew/share/gtksourceview-4 "${APP_SHARE_DIR}"
cp -f /opt/homebrew/share/glib-2.0/schemas/gschema* "${APP_SHARE_DIR}/glib-2.0/schemas"
glib-compile-schemas ${APP_SHARE_DIR}/glib-2.0/schemas

msg "Removing static libraries and cache files:"
find -E "${LIB}" -type f -regex '.*\.(a|la|cache)$' | while read -r; do rm "${REPLY}"; done

# Make Frameworks folder flat
msg "Flattening the Frameworks folder"
cp -RL "${LIB}"/gdk-pixbuf-2.0/2*/loaders/* "${LIB}"
cp "${LIB}"/gtk-3.0/3*/immodules/*.{dylib,so} "${LIB}"
cp "${LIB}"/gio/modules/*.{dylib,so} "${LIB}"
rm -r "${LIB}"/gtk-3.0
rm -r "${LIB}"/gdk-pixbuf-2.0
rm -r "${LIB}"/gio

# ModifyInstallNames

# find "${TARGETDIR}/bin" -type f -path '*.dll.a' -exec rm '{}' \;
lib_dependency_analyze ${APP_LIB_DIR} ${APP_LIB_DIR}
lib_dependency_analyze ${APP_EXE_DIR} ${APP_LIB_DIR}

chmod -R 766 $APP_LIB_DIR

# Build GTK3 pixbuf loaders & immodules database
msg "Build GTK3 databases:"
/opt/homebrew/bin/gdk-pixbuf-query-loaders "${LIB}"/libpixbufloader-*.so > "${ETC}"/gtk-3.0/gdk-pixbuf.loaders
/opt/homebrew/bin/gtk-query-immodules-3.0 "${LIB}"/im-* > "${ETC}"/gtk-3.0/gtk.immodules || /opt/homebrew/bin/gtk-query-immodules "${LIB}"/im-* > "${ETC}"/gtk-3.0/gtk.immodules
sed -i.bak -e "s|${PWD}/ThiefMD.app/Contents/|/Applications/ThiefMD.app/Contents/|" "${ETC}"/gtk-3.0/gdk-pixbuf.loaders "${ETC}/gtk-3.0/gtk.immodules"
sed -i.bak -e "s|/opt/homebrew/share/|/Applications/ThiefMD.app/Contents/share/|" "${ETC}"/gtk-3.0/gtk.immodules
sed -i.bak -e "s|/opt/homebrew/|/Applications/ThiefMD.app/Contents/Frameworks/|" "${ETC}"/gtk-3.0/gtk.immodules
rm "${ETC}"/*.bak

lib_change_paths \
  @executable_path/../Frameworks \
  $APP_LIB_DIR \
  $APP_EXE_DIR/com.github.kmwallio.thiefmd

lib_change_paths \
  @executable_path/../Frameworks \
  $APP_LIB_DIR \
  $APP_CON_DIR/MacOs/com.github.kmwallio.thiefmd

lib_change_paths \
  @executable_path/../Frameworks \
  $APP_LIB_DIR \
  $APP_EXE_DIR/gdbus

lib_change_paths \
  @executable_path/../Frameworks \
  $APP_LIB_DIR \
  $APP_EXE_DIR/gdk-pixbuf-query-loaders

lib_change_siblings $APP_LIB_DIR @loader_path

# Gio modules
gio_modules="$(find $APP_LIB_DIR/gio/modules/ -name \*.dylib -o -name \*.so -type f)"
for gio_module in $gio_modules; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $gio_module
done

# Gdk-pixbuf plugins
pixbuf_plugins="$(find $APP_LIB_DIR/gdk-pixbuf-2.0/2.10.0/loaders/ -name \*.dylib -o -name \*.so -type f)"
for pixbuf_plugin in $pixbuf_plugins; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $pixbuf_plugin
done

# Gtk modules(immodule and printbackend)
gtk_im_modules="$(find $APP_LIB_DIR/gtk-3.0/3.0.0/immodules/ -name \*.dylib -o -name \*.so -type f)"
for gtk_immodule in $gtk_im_modules; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $gtk_immodule
done

gtk_print_modules="$(find $APP_LIB_DIR/gtk-3.0/3.0.0/printbackends/ -name \*.dylib -o -name \*.so -type f)"
for print_module in $gtk_print_modules; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $print_module
done

# Database plugins
db_plugins="$(find $APP_LIB_DIR/plugin/ -name \*.dylib -o -name \*.so -type f)"
for db_plugin in $db_plugins; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $db_plugin
done

# Libgda providers
gda_providers="$(find $APP_LIB_DIR/libgda-5.0/providers/ -name \*.dylib -o -name \*.so -type f)"
for gda_provider in $gda_providers; do
  lib_change_paths \
    @executable_path/../Frameworks \
    $APP_LIB_DIR \
    $gda_provider
done

# msg "Registering @rpath in Frameworks folder."
# for frameworklibs in "${LIB}"/*{dylib,so,cli}; do
#     install_name_tool -delete_rpath ${LOCAL_PREFIX}/lib "${frameworklibs}"
#     install_name_tool -add_rpath /Applications/"${LIB}" "${frameworklibs}"
# done

# ModifyInstallNames

echo "\n--------\n" >> "${APP_RES_DIR}/AboutThisBuild.txt"
echo "Bundle system: $(sysctl -n machdep.cpu.brand_string)" >> "${APP_RES_DIR}/AboutThisBuild.txt"
echo "Bundle OS:     $(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion) $(uname -mrs)" >> "${APP_RES_DIR}/AboutThisBuild.txt"
echo "Bundle date:   $(date -Ru) UTC" >> "${APP_RES_DIR}/AboutThisBuild.txt"
echo "Bundle epoch:  $(date +%s)" >> "${APP_RES_DIR}/AboutThisBuild.txt"
echo "Bundle UUID:   $(uuidgen|tr 'A-Z' 'a-z')" >> "${APP_RES_DIR}/AboutThisBuild.txt"

echo -n "[done]"

codesign -s "4E21403E16CC5E305EBEF5A0D879499068382877" "${APP_TOP_DIR}"
