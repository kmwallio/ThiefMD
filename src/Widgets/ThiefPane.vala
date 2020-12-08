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
    public class ThiefPane : Paned {
        private ThiefApp instance;
        public ThiefPane (Orientation orientation, ThiefApp thiefapp) {
            set_orientation (orientation);
            instance = thiefapp;
            add_events (Gdk.EventMask.POINTER_MOTION_MASK);
            still_in_motion = new TimedMutex (Constants.MOUSE_IN_MOTION_TIME);
            clear_bar = new TimedMutex (Constants.MOUSE_MOTION_CHECK_TIME);
        }

        private TimedMutex still_in_motion;
        private TimedMutex clear_bar;
        private double mouse_x = 0;
        private double mouse_y = 0;
        private double last_x = 0;
        private double last_y = 0;
        public override bool motion_notify_event (EventMotion event ) {
            base.motion_notify_event (event);
            var settings = AppSettings.get_default ();
            last_x = event.x_root;
            last_y = event.y_root;

            instance.save_pane_position ();

            if (!settings.hide_toolbar) {
                return true;
            }

            if (!still_in_motion.can_do_action ()) {
                return true;
            }

            double d_x = (mouse_x - last_x).abs ();
            double d_y = (mouse_y - last_y).abs ();
            double d = (d_x * d_x) + (d_y * d_y);
            if (d < Constants.MOUSE_SENSITIVITY) {
                return true;
            }
            debug ("Distance: %f", d);

            if (instance.toolbar.hidden){
                instance.toolbar.show_headerbar ();
                if (clear_bar.can_do_action ()) {
                    Timeout.add (Constants.MOUSE_MOTION_CHECK_TIME + 100, hide_the_bar);
                }
            }

            return true;
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