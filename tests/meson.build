if get_option('build_tests')

cc = meson.get_compiler('c')

# Find libMarkdown
libmarkdown = dependency('libmarkdown', version: '>= 2.2.1', required: false)
if libmarkdown.found() == false
    cc = meson.get_compiler('c')
    libmarkdown = cc.find_library('libmarkdown', required: true)
endif

testing = executable('tests',
    'ThiefTests.vala',
    'ImageExtractionTests.vala',
    'MarkdownTests.vala',
    'TestSettings.vala',
    meson.source_root() + '/src/Controllers/Pandoc.vala',
    meson.source_root() + '/src/Controllers/UserData.vala',
    meson.source_root() + '/src/Constants/ThiefProperties.vala',
    dependencies: [
        dependency('gobject-2.0'),
        dependency('gtksourceview-4'),
        dependency('gtk+-3.0'),
        dependency('gtkspell3-3.0'),
        dependency('webkit2gtk-4.0'),
        dependency('clutter-1.0'),
        dependency('json-glib-1.0'),
        dependency('gee-0.8'),
        dependency('libarchive'),
        dependency('libxml-2.0'),
        dependency('libsecret-1'),
        dependency('libhandy-1'),
        libmarkdown
    ],
    vala_args: [
        '--pkg=posix',
        '--vapidir=' + meson.source_root() + '/vapi'
        ],
    install: false
)

test('ThiefTests', testing)

endif
