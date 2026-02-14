/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD.Controllers;
using Gdk;
using Gtk;

namespace ThiefMD.Widgets {
    public class MouseMotionListener : Object {
        private ThiefApp instance;
        private Gtk.EventControllerMotion motion_controller;

        public MouseMotionListener (ThiefApp thiefapp) {
            instance = thiefapp;
            still_in_motion = new TimedMutex (Constants.MOUSE_IN_MOTION_TIME);
            clear_bar = new TimedMutex (Constants.MOUSE_MOTION_CHECK_TIME);
        }

        private TimedMutex still_in_motion;
        private TimedMutex clear_bar;
        private double mouse_x = 0;
        private double mouse_y = 0;
        private double last_x = 0;
        private double last_y = 0;

        public void attach (Gtk.Widget target) {
            motion_controller = new Gtk.EventControllerMotion ();
            motion_controller.motion.connect ((x, y) => {
                handle_motion (x, y);
            });
            target.add_controller (motion_controller);
        }

        private void handle_motion (double x, double y) {
            var settings = AppSettings.get_default ();
            last_x = x;
            last_y = y;

            if (!settings.hide_toolbar) {
                return;
            }

            if (!still_in_motion.can_do_action ()) {
                return;
            }

            // Avoid flickering by only reacting to meaningful travel and when near the top edge.
            double d_x = Math.fabs (mouse_x - last_x);
            double d_y = Math.fabs (mouse_y - last_y);
            double d = (d_x * d_x) + (d_y * d_y);
            if (d < Constants.MOUSE_SENSITIVITY) {
                return;
            }

            // Only reveal when the pointer is near the top region of the window.
            double reveal_zone = instance.toolbar.get_allocated_height ();
            if (reveal_zone <= 0) {
                reveal_zone = 80;
            }
            if (last_y > reveal_zone + Constants.TOP_MARGIN) {
                return;
            }

            if (instance.toolbar.hidden) {
                instance.toolbar.show_headerbar ();
                if (clear_bar.can_do_action ()) {
                    Timeout.add (Constants.MOUSE_MOTION_CHECK_TIME + 100, hide_the_bar);
                }
            }
        }

        private bool hide_the_bar () {
            var settings = AppSettings.get_default ();
            // Check if mouse is still in motion
            if (still_in_motion.can_do_action () && settings.hide_toolbar && !settings.menu_active) {
                instance.toolbar.hide_headerbar ();
                mouse_x = last_x;
                mouse_y = last_y;
                return false;
            }

            return true;
        }
    }
}