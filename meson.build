# Name our project
project('com.github.kmwallio.thiefmd', ['vala', 'c'],
    version: '0.0.1'
)

# Import main lib files
gnome = import('gnome')
i18n = import('i18n')

# Compile the GResources for this project
asresources = gnome.compile_resources(
    'as-resources', 'data/app.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Set this for convenience
conf = configuration_data()

# Get the package data directory under Meson
pkgdatadir = join_paths([ get_option('prefix'),
                          get_option('datadir'),
                          'com.github.kmwallio.thiefmd' ])

conf.set_quoted('PKGDATADIR', pkgdatadir)

# Other configs
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Arguments for C
c_args = [
  '-include', 'config.h',
  '-w'
]

cc = meson.get_compiler('c')

# Find libMarkdown
libmarkdown = dependency('libmarkdown', version: '>= 2.2.1', required: false)
if libmarkdown.found() == false
    cc = meson.get_compiler('c')
    libmarkdown = cc.find_library('libmarkdown', required: true)
endif

# Let's define our executable
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants/AppSettings.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/Sheets.vala',
    'src/Widgets/Sheet.vala',
    'src/Widgets/Editor.vala',
    'src/Widgets/Library.vala',
    'src/Widgets/NewSheet.vala',
    'src/Widgets/KeyBindings.vala',
    'src/Widgets/QuickPreferences.vala',
    'src/Controllers/FileManager.vala',
    'src/Controllers/Dialogs.vala',
    'src/Controllers/SheetManager.vala',
    'src/Controllers/UI.vala',
    asresources,
    c_args: c_args,
    dependencies: [
        dependency('granite'),
        dependency('gobject-2.0'),
        dependency('gtksourceview-3.0'),
        dependency('gtk+-3.0'),
        dependency('gtkspell3-3.0')
    ],
    vala_args: [
        meson.source_root() + '/vapi/config.vapi'
    ],
    install : true
)

# Add in a post install script
meson.add_install_script('meson/post_install.py')

# Add subfolders for Meson to look
subdir('data')
