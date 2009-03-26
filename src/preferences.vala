/*
 * File Name: preferences.vala
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

namespace FSO
{
    public class Preferences:System
    {
        public static string BUS_NAME = "org.freesmartphone.opreferencesd";
        public static string IFACE = "org.freesmartphone.Preferences";
        public static string OBJ_PATH = "/org/freesmartphone/Preferences";

        private dynamic DBus.Object object;

        public Preferences( Logger l, DBus.Connection c )
        {
            base( l,c );
        }
        public override void run(  )
        {
            debug( "Gathering preferences ..." );
            this.object = this.con.get_object( BUS_NAME, OBJ_PATH, IFACE );
            try
            {
                this.object.GetServices( this.get_services );
            }
            catch (  GLib.Error e )
            {
                debug( "Retrieving Info for services/profiles: %s", e.message );
            }
        }
        private void get_services( dynamic DBus.Object obj, string[] services, GLib.Error error )
        {
            if( error != null )
            {
                debug( "GetServices: %s",error.message );
            }
            else
            {
                foreach( string service in services )
                {
                    try
                    {
                        this.object.GetService(  service, this.get_service );
                    }
                    catch (  GLib.Error e )
                    {
                        debug( "GetService for %s: %s", service, e.message );
                    }
                }
            }
        }
        private void get_service( dynamic DBus.Object obj, DBus.ObjectPath service, GLib.Error error )
        {
            if( error != null )
            {
                debug( "GetService failed: %s", error.message );
            }
            else
            {
                var tmpobj = new Service( this.logger, this.con, service );
                this.subsystems.prepend( tmpobj );
                tmpobj.run(  );
            }
        }

        public class Service:Subsystem
        {
            public static string IFACE = "org.freesmartphone.Preferences.Service";
            public Service( Logger l, DBus.Connection c, string name )
            {

                base( l,c,name );
                this._OBJ_PATH = "%s/%s".printf( OBJ_PATH, name );
                this._BUS_NAME = BUS_NAME;
                this._IFACE = IFACE;
            }
            public override void run(  )
            {
                debug( "Gathering Service object for %s", this.name );
                base.run(  );
                this.object.Notify += this.service_notify;
            }
            public override void stop(  )
            {
                this.object.Notify -= this.service_notify;
                base.stop(  );
            }
            private void service_notify( dynamic DBus.Object obj, string key, Value v )
            {
                this.logger.log( "Preferences.Service" ).signal( "Notify" ).name( key ).type( v.type(  ) ).value( value_to_string( v ) ).end(  );
            }
        }
    }
}
