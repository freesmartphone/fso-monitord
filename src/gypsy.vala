/*
 * File Name: gypsy.vala
 * Creation Date: 06-02-2009
 * Last Modified: 06-02-2009
 *
 * Authored by Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
using GLib;
using DBus;
public namespace FSO
{
    public class Gypsy: System
    {
        private static const BUS_NAME = "org.freesmartphone.ogpsd"
        private class Accuracy: Subsystem
        {
            public static const string IFACE = "org.freedesktop.Gypsy.Accuracy";
        }
        private class Course: Subsystem
        {
            private static const string IFACE = "org.freedesktop.Gypsy.Course";
        }
        private class Device: Subsystem
        {
            private const string IFACE = "org.freedesktop.Gypsy.Device";
        }
        private class Position: Subsystem
        {
            private const string IFACE = "org.freedesktop.Gypsy.Position";
        }
        private class Time
        {
            private const string IFACE = "org.freedesktop.Gypsy.Time";
        }
    }
}
