/*
 * File Name: usage.vala
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
using DBus;
using GLib;

namespace FSO
{
    public class Usage: System
    {
        public static const string BUS_NAME = "org.freesmartphone.ousaged";
        public static const string IFACE = "/org/freesmartphone/Usage";
        public static const string OBJ_PATH = "org.freesmartphone.Usage";
        private dynamic DBus.Object object;
        public Usage(Logger l, DBus.Connection c)
        {
            base(l,c);
            this.busname = BUS_NAME;
        }
        public override void run()
        {
            base.run();
            //this.object = this.con.get_object( BUS_NAME, OBJ_PATH, IFACE );
            this.object.RessourceAvailable += this.ressource_available;
            this.object.RessourceChanged += this.ressource_changed;
            this.object.SystemAction += this.system_action;
            try
            {
                this.object.Ping();
            }
            catch (GLib.Error e)
            {
                debug( "Ping failed: %s", e.message );
            }
        }
        public override void stop(  )
        {
            this.object.RessourceAvailable -= this.ressource_available;
            this.object.RessourceChanged -= this.ressource_changed;
            this.object.SystemAction -= this.system_action;
            this.object = null;
        }
        private void ressource_available( dynamic DBus.Object obj, string name, bool state)
        {
            this.logger.log("USAGE").signal( "ResourceAvailable" )
                .name("name").type( typeof(string)).value( name )
                .name( "state" ).type(typeof(bool)).value( state.to_string() ).end();
        }
        private void ressource_changed( dynamic DBus.Object obj, string name, bool state, HashTable<string, Value?> attr)
        {
            this.logger.log("USAGE").signal( "RessourceChanged:")
                .name( "name").type(typeof(string)).value( name )
                .name( "state").type( typeof(string)).value(state.to_string())
                .name( "attributes" ).attributes( attr ).end();
        }
        private void system_action(dynamic DBus.Object obj, string action)
        {
            this.logger.log("USAGE").signal( "SystemAction" ).name( "action" ).type( typeof( string ) ).value( action).end();
        }
    }
}
