/*
 * File Name: phone.vala
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

namespace FSO
{
    public class Phone: System
    {
        public static string BUS_NAME = "org.freesmartphone.ophoned";
        public static string IFACE = "org.freesmartphone.Phone";
        public static string OBJ_PATH = "/org/freesmartphone/Phone";
        private dynamic DBus.Object object;
        public Phone( Logger l, DBus.Connection c )
        {
            base( l,c );
        }
        public override void run( )
        {
            debug( "Gathering Phone object..." );
            this.object = this.con.get_object( BUS_NAME, OBJ_PATH, IFACE );
            this.object.Incoming += this.incoming_call;
        }
        private void incoming_call( dynamic DBus.Object obj, DBus.ObjectPath call )
        {
            this.logger.log( "Phone" ).signal( "Incoming" ).name( "call" ).value( call ).end( );
            Call tmpobj = new Call( this.logger, this.con, call ); 
            this.subsystems.prepend(tmpobj);
            tmpobj.run( );
            //XXX: I hope this work. The Object will cleanup on its own
            //tmpobj.ref( );
        }
        public class Call: Subsystem
        {
            public static string IFACE = "org.freesmartphone.Phone.Call";
            private string cur_status = null;

            public Call( Logger l, DBus.Connection c, string name )
            {
                debug( "New call on: %s", name );
                base( l,c,name );
                this._IFACE = IFACE;
                this._BUS_NAME = BUS_NAME;
                this._OBJ_PATH = name;
                this.run(  );
            }
            public override void run( )
            {
                base.run( );
                this.object.Incoming += this.incoming_call;
                this.object.Release += this.release_call;
                this.object.Outgoing += this.outgoing_call;
                this.object.Activated += this.activated_call;
                try
                {
                    this.object.GetStatus( this.get_status );
                }
                catch (  GLib.Error e )
                {
                    debug( "Calling GetStatus:%s",e.message );
                }
            }
            private void incoming_call( dynamic DBus.Object obj )
            {
                debug( "refcount: %u", this.ref_count );
                this.logger.log( "Phone.Call" ).log( "Incoming" ).end( );
            }
            private void release_call( dynamic DBus.Object obj )
            {
                debug( "refcount: %u", this.ref_count );
                this.logger.log( "Phone.Call" ).log( "Release" ).end( );
                try
                {
                    this.object.Remove( );
                }
                catch ( GLib.Error e )
                {
                    debug( "Removing Call Object: %s", e.message );
                }
                debug( "destroying Call Object %X",( uint )this );
                this = null;
            }
            private void outgoing_call( dynamic DBus.Object obj )
            {
                debug( "refcount: %u", this.ref_count );
                this.logger.log( "Phone.Call" ).log( "Outgoing" ).end( );
            }
            private void activated_call( dynamic DBus.Object obj )
            {
                debug( "refcount: %u", this.ref_count );
                this.logger.log( "Phone.Call" ).log( "Activated" ).end( );
            }
            private void get_status( dynamic DBus.Object obj, string status, GLib.Error error )
            {
                if( error != null )
                {
                    debug( "Can't get Callstatus: %s", error.message );
                    this.cur_status = "UNKNOWN";
                }
                else
                {
                    this.cur_status = status;
                }
            }
        }
    }
}
