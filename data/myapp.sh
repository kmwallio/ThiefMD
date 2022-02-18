#!/bin/sh

name=`basename "$0"`
bundle_app="$( cd "$( dirname "$0" )/../.." >/dev/null 2>&1 && pwd )"
bundle_contents="$bundle_app"/Contents
bundle_res="$bundle_app"
bundle_lib="$bundle_res"/lib
bundle_bin="$bundle_res"/bin
bundle_data="$bundle_res"/share
bundle_etc="$bundle_res"/etc

export DYLD_LIBRARY_PATH="$bundle_lib"
export XDG_CONFIG_DIRS="$bundle_etc"/xdg
export XDG_DATA_DIRS="$bundle_data"
export GTK_DATA_PREFIX="$bundle_res"
export GTK_EXE_PREFIX="$bundle_res"
export GTK_PATH="$bundle_res:$bundle_lib:$bundle_bin:$bundle_data"
export GTK_THEME="Adwaita"
# GIO modules
export GIO_MODULE_DIR="$bundle_lib/gio/modules"
# PANGO_* is no longer needed for pango >= 1.38
export PANGO_RC_FILE="$bundle_etc/pango/pangorc"
export PANGO_SYSCONFDIR="$bundle_etc"
export PANGO_LIBDIR="$bundle_lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:`pwd`/lib"
APP=$name
# Pixbuf plugins and update cache
export GDK_PIXBUF_MODULEDIR="$bundle_lib/gdk-pixbuf-2.0/2.10.0/loaders"
export GDK_PIXBUF_MODULE_FILE="$bundle_lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
$bundle_contents/MacOS/gdk-pixbuf-query-loaders --update-cache $GDK_PIXBUF_MODULEDIR/*.so
if [ `uname -r | cut -d . -f 1` -ge 10 ]; then
    export GTK_IM_MODULE_FILE="$bundle_etc/gtk-3.0/gtk.immodules"
fi
cd "${0%/*}"
if [ `uname` == 'Darwin' ]; then
    ./com.github.kmwallio.thiefmd
else
    export LD_LIBRARY_PATH="`pwd`/lib"
    bin/com.github.kmwallio.thiefmd
fi