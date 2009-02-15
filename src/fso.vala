/*
 * File Name: fso.vala
 * Creation Date: 06-02-2009
 * Last Modified: 09-02-2009
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

namespace FSO
{
    public class Framework: System
    {
        public const string BUS_NAME   = "org.freesmartphone.frameworkd";
        public const string OBJ_PATH   = "/org/freesmartphone/Framework";
        public string IFACE      = "org.freesmartphone.Framework";

        private dynamic DBus.Object object;
        
        public Framework( FSO.Logger l, DBus.Connection c )
        {
            base(l,c);
        }

        public override void run()
        {
            this.object = this.con.get_object( BUS_NAME, OBJ_PATH, IFACE );
            debug( "Attached to frameworkd %s. Gathering objects...", this.object.GetVersion() );
        }
        public override void stop()
        {
            base.stop();
        }
    }
}
