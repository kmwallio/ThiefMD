/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified August 29, 2020
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

using ThiefMD;
using ThiefMD.Controllers;
using ThiefMD.Enrichments;

namespace ThiefMD.Widgets {
    public class QuickPreferences : Gtk.Popover {
        public Gtk.Label _label;
        public Gtk.Entry _file_name;
        public Gtk.Button _create;
        public Gtk.ToggleButton _spellcheck_button;
        public Gtk.ToggleButton _writegood_button;
        public Gtk.ToggleButton _grammar_button;
        public Gtk.ToggleButton _typewriter_button;
        private Gtk.Window _instance;
        private bool am_mobile = false;
        private Gtk.Box menu_box;

        public QuickPreferences (Gtk.Window instance) {
            _instance = instance;
            var settings = AppSettings.get_default ();

            _typewriter_button = new Gtk.ToggleButton.with_label ((_("Typewriter Scrolling")));
            _typewriter_button.tooltip_text = _("Toggle Typewriter Scrolling");
            _typewriter_button.set_active (settings.typewriter_scrolling);

            _typewriter_button.toggled.connect (() => {
                settings.typewriter_scrolling = _typewriter_button.active;
            });

            _spellcheck_button = new Gtk.ToggleButton.with_label ((_("Check Spelling")));
            _spellcheck_button.tooltip_text = _("Toggle Spellcheck");
            _spellcheck_button.set_active (settings.spellcheck);

            _spellcheck_button.toggled.connect (() => {
                settings.spellcheck = _spellcheck_button.active;
            });

            _writegood_button = new Gtk.ToggleButton.with_label ((_("Write Good")));
            _writegood_button.tooltip_text = _("Toggle Write Good");
            _writegood_button.set_active (settings.writegood);

            _writegood_button.toggled.connect (() => {
                settings.writegood = _writegood_button.active;
            });

            _grammar_button = new Gtk.ToggleButton.with_label ((_("Check Grammar")));
            _grammar_button.tooltip_text = _("Toggle Grammar Checking");
            _grammar_button.set_active (settings.grammar);

            _grammar_button.toggled.connect (() => {
                GrammarThinking gram = new GrammarThinking ();
                if (gram.language_detected ()) {
                    settings.grammar = _grammar_button.active;
                } else {
                    var dialog = new Adw.MessageDialog (ThiefApp.get_instance (), _("Grammar check is not available for your language"), "");
                    dialog.add_response ("close", _("Close"));
                    dialog.set_default_response ("close");
                    dialog.set_close_response ("close");
                    dialog.present ();
                }
            });

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var preview_button = new Gtk.Button ();
            preview_button.label = (_("Preview"));
            preview_button.has_tooltip = true;
            preview_button.tooltip_text = _("Launch Preview");
            preview_button.clicked.connect (() => {
                if (_instance is ThiefApp) {
                    PreviewWindow pvw = PreviewWindow.get_instance ();
                    pvw.show ();
                } else {
                    var editor = (SoloEditor)_instance;
                    editor.toggle_preview ();
                }
            });

            var export_button = new Gtk.Button ();
            export_button.label = (_("Publishing Preview"));
            export_button.has_tooltip = true;
            export_button.tooltip_text = _("Open Export Window");
            export_button.clicked.connect (() => {
                if (_instance is ThiefApp) {
                    PublisherPreviewWindow ppw = new PublisherPreviewWindow (SheetManager.get_markdown ().replace(ThiefProperties.THIEF_MARK_CONST, ""), is_fountain (settings.last_file));
                    ppw.show ();
                } else if (_instance is SoloEditor) {
                    var editor = (SoloEditor)_instance;
                    editor.export ();
                }
            });

            var search_button = new Gtk.Button ();
            search_button.label = (_("Search Library"));
            search_button.has_tooltip = true;
            search_button.tooltip_text = _("Open Search Window");
            search_button.clicked.connect (() => {
                if (_instance is ThiefApp) {
                    UI.show_search ();
                } else if (_instance is SoloEditor) {

                }
            });

            var preferences_button = new Gtk.Button ();
            preferences_button.label = (_("Preferences"));
            preferences_button.has_tooltip = true;
            preferences_button.tooltip_text = _("Edit Preferences");
            preferences_button.clicked.connect (() => {
                Preferences prf = new Preferences();
                prf.present ();
            });

            var about_button = new Gtk.Button ();
            about_button.label = (_("About"));
            about_button.has_tooltip = true;
            about_button.tooltip_text = _("About ThiefMD");
            about_button.clicked.connect (() => {
                new About ().present (ThiefApp.get_instance ());
            });

            menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            menu_box.margin_top = 6;
            menu_box.margin_bottom = 6;
            menu_box.margin_start = 6;
            menu_box.margin_end = 6;
            // Add a CSS class so popover buttons can be styled consistently, even with custom themes
            menu_box.add_css_class ("quickprefs");
            menu_box.append (_typewriter_button);
            menu_box.append (_spellcheck_button);
            if (GrammarThinking.language_supported (settings.spellcheck_language)) {
                menu_box.append (_grammar_button);
            }
            menu_box.append (_writegood_button);
            menu_box.append (separator2);
            menu_box.append (preview_button);
            if (_instance is ThiefApp && ((ThiefApp)_instance).show_touch_friendly) {
                menu_box.append (export_button);
                menu_box.append (search_button);
                am_mobile = true;
            } else if (_instance is SoloEditor) {
                menu_box.append (export_button);
            }
            menu_box.append (preferences_button);
            menu_box.append (about_button);

            settings.changed.connect (update_ui);

            set_child (menu_box);
        }

        private void rebuild_menu_layout () {
            // GTK4: single menu layout reused for all modes.
        }

        public void update_ui () {
            var settings = AppSettings.get_default ();
            _typewriter_button.set_active (settings.typewriter_scrolling);
            _spellcheck_button.set_active (settings.spellcheck);
            _grammar_button.set_active (settings.grammar);
            _writegood_button.set_active (settings.writegood);

            rebuild_menu_layout ();
        }
    }
}
