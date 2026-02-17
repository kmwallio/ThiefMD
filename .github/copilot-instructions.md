This is a Vala based repository for a markdown editor. We aim for a casual laid back atmosphere, but deliver serious and reliable code.

Please follow these guidelines when contributing:

## General

  * Be respectful and considerate in your interactions with others.
  * Write clear and concise commit messages.
  * Follow the existing code style and conventions.
  * Prefer small, focused changes that are easy to review.
  * Include tests for any new features or bug fixes.
  * Document your code where necessary. Comments should help readers and middle school level understand the code.

## Repository Structure

  * `src/`: Contains the source code for the application.
    * `src/Widgets/`: Contains custom GTK widgets used in the application.
    * `src/Controllers/`: Contains controller classes that manage application logic and interactions.
    * `src/Enrichments/`: Contains code for enhancing GtkSourceView's with life improving features for writers.
    * `src/Exporters/`: Contains code for publishing documents to local files.
    * `src/Connections`: Contains code for publishing documents to remote platforms.
  * `tests/`: Contains unit tests for the application.
  * `data/`: Linux packaging files and non-executable resources.
  * `flatpak/`: Flatpak packaging files for local validation.
  * `vapi/`: Custom VAPI files for external libraries.

## Key Guidelines

1. Follow Vala best practices and patterns.
2. Maintain existing code structure and organization.
3. Avoid large refactors unless explicitly requested.
4. Ensure that new code is well-tested and does not break existing functionality.
5. Use descriptive variable and function names that contain a fun tone or sense of humor.
6. Keep comments short, clear, and easy for a middle school reader.
7. When in doubt, ask for feedback or clarification from the maintainers.
8. Have fun and enjoy contributing to the project!

## Testing

  * Add or update tests under `tests/` for new behavior.
  * When you change a feature, update any affected test expectations.
  * If tests are not possible, explain why and what was verified manually.

## Style Notes

  * Prefer ASCII text unless the file already uses non-ASCII characters.
  * Keep naming consistent with nearby code.
  * Avoid introducing new dependencies unless requested.

## Build and Test

  * Configure: `meson setup build`
  * Build: `meson compile -C build`
  * Run tests: `meson test -C build`
  * Run the app: `./build/com.github.kmwallio.thiefmd`

## Flatpak Build and Test

  * Prereqs: `org.gnome.Platform//49` and `org.gnome.Sdk//49`
  * Change directory: `cd flatpak`
  * Build/install: `flatpak-builder --force-clean --user --install build-dir com.github.kmwallio.thiefmd.json`
  * Run: `flatpak run com.github.kmwallio.thiefmd`
