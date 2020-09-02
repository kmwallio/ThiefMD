/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 1, 2020
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

using Gtk;

namespace ThiefMD {
    public const int BYTE_BITS = 8;
    public const int WORD_BITS = 16;
    public const int DWORD_BITS = 32;

    public enum Target {
        STRING
    }

    public const TargetEntry[] target_list = {
        { "STRING" , 0, Target.STRING }
    };
}