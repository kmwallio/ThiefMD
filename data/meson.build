icon_sizes = ['symbolic', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach


font_types = ['Bold', 'Italic', 'BoldItalic', 'Regular']
fonts = ['Courier Prime', 'iAWriterDuospace', 'Stolen Victory Duo', 'Stolen Victory Sans']

foreach f : fonts
    foreach ft : font_types
        if (run_command('[', '-e', join_paths('font', f + '-' + ft + '.ttf'), ']').returncode() == 0)
            # message('Installing ' + f + '-' + ft + '.ttf')
            install_data(
                join_paths('font', f + '-' + ft + '.ttf'),
                install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'thiefmd')
            )
        endif
    endforeach
endforeach

install_data(
    meson.project_name() + '.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    meson.project_name() + '.appdata.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    join_paths('schemes', 'thiefmd.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-5', 'styles')
)

install_subdir(
    join_paths('language-specs'),
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'gtksourceview-5')
)

install_data(
    join_paths('preview', 'preview.css'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'styles' ])
)

install_data(
    join_paths('highlight', 'highlight.css'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'styles' ])
)

install_data(
    join_paths('highlight', 'highlight.js'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'scripts' ])
)

install_data(
    join_paths('katex', 'katex.min.css'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'styles' ])
)

install_subdir(
    join_paths('katex', 'fonts'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'styles' ])
)

install_data(
    join_paths('katex', 'katex.min.js'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'scripts' ])
)

install_data(
    join_paths('katex', 'auto-render.min.js'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'scripts' ])
)

install_data(
    join_paths('fountain', 'fountain.css'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'styles' ])
)

install_data(
    join_paths('fountain', 'fountain.js'),
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.kmwallio.thiefmd', 'scripts' ])
)

gnome.compile_schemas()