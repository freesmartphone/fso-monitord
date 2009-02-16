/*
 * File Name: gsm.vala
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

using GLib;

namespace FSO
{
    public class GSM:System
    {
        public static const string BUS_NAME = "org.freesmartphone.ogsmd";
        public GSM( Logger l, DBus.Connection c)
        {
            base(l,c);
            this.subsystems.prepend( new Call( l,c ) );
            this.subsystems.prepend( new CellBroadcast( l,c ) );
            this.subsystems.prepend( new HomeZone( l,c ) );
            this.subsystems.prepend( new MUX( l,c ) );
            this.subsystems.prepend( new Network( l,c ) );
            this.subsystems.prepend( new PDP( l,c ) );
            this.subsystems.prepend( new Phone( l,c ) );
            this.subsystems.prepend( new SIM( l,c ) );
            this.subsystems.prepend( new SMS( l,c ) );
        }
        public class Call:Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.Call";

            public Call( Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
    
            public override void run()
            {
                base.run();
                this.object.CallStatus += this.call_status_changed;
                debug( "Started GSM.Call" );
            }
            public override void stop()
            {
                base.stop();
            }
            private void call_status_changed( dynamic DBus.Object obj, int id,
                    string status, GLib.HashTable<string,Value?> properties)
            {
                this.logger.log("CALL").signal( "Status" )
                        .name( "ID" ).type( typeof( int) ).value( id.to_string() )
                        .name( "status").type ( typeof( string ) ).value( status )
                        .name( "properties" ).attributes( properties ).end();
            }
        }
        public class CellBroadcast: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.CB";
            public CellBroadcast( FSO.Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.IncomingCellBroadcast += this.incoming_cb;
                debug( "Started GSM.CB" );
            }
            public override void stop()
            {
                base.stop();
            }
            private void incoming_cb(dynamic DBus.Object obj, int serial, int channel,
                    int encoding, int page, string data)
            {
                this.logger.log("CB").signal("IncomingCellBroadcast" )
                        .name( "serial" ).type( typeof( int ) ).value( serial.to_string() )
                        .name( "channel" ).type( typeof( int ) ).value( channel.to_string() )
                        .name( "encoding" ).type( typeof( int ) ).value( encoding.to_string() )
                        .name( "page" ).type( typeof( int ) ).value( page.to_string() )
                        .name( "data" ).type( typeof( string ) ).value( data ).end( );
            }

        }
        public class HomeZone: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Server";
            public static const string IFACE  = "org.freesmartphone.GSM.HZ";
            private string current_home_zone;
            public HomeZone( FSO.Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.HomeZone += this.home_zone_changed;
                try
                {
                    this.object.GetHomeZone( this.get_home_zone );
                }
                catch (  GLib.Error e )
                {
                    debug( "GetHomeZone: %s:", e.message );
                }
                debug( "Started GSM.HZ" );
            }
            public override void stop()
            {
                base.stop();
            }
            private void get_home_zone(dynamic DBus.Object obj, string zone, GLib.Error error)
            {
                if( error != null)
                {
                    log("HZ", 0, "Can't get homezone: %s", error.message );
                }
                else
                {
                    this.current_home_zone = zone;
                }
            }

            private void home_zone_changed( dynamic GLib.Object obj, string zone)
            {
                this.logger.log("HZ").signal( "HomeZoneStatus" ).name( "zone" ).type( typeof(string)).from(this.current_home_zone).to( zone).end();
                this.current_home_zone = zone;
            }

        }
        public class MUX: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.MUX";
            public MUX( FSO.Logger l, DBus.Connection c,string name = "" )
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.Status += this.status_changed;
                debug( "Started GSM.MUX" );
            }
            public override void stop()
            {
                this.object.Status -= this.status_changed;
                base.stop();
            }
            private void status_changed( dynamic DBus.Object obj, string status)
            {
                logger.log("GSM.MUX").name("status").type( typeof(string) ).value( status).end();
            }
            
        }
        public class Network: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.Network";
            private string current_gsm_cipher = "UNKNOWN";
            private string current_gprs_cipher = "UNKNOWN";
            private int current_signal_strength;
            public Network( FSO.Logger l, DBus.Connection c,string name = "" )
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.NetworkStatus += this.network_status_changed;
                this.object.SignalStrength += this.network_signal_strength_changed;
                this.object.IncomingUssd += this.network_incoming_ussd;
                this.object.CipherStatus += this.cipher_status_changed;
                try
                {
                    this.object.GetSignalStrength( this.set_signal_strength );
                }
                catch ( GLib.Error e )
                {
                    debug( "GetSignalStatus: %s", e.message );
                }
                debug( "Started GSM.Network" );
            }
            public override void stop()
            {
                base.stop();
            }
            private void cipher_status_changed(dynamic DBus.Object obj, string gsm, string gprs )
            {
                this.logger.log("NETWORK").signal( "CipherStatus")
                    .name( "GSM" ).type(typeof(string)).from( this.current_gsm_cipher ).to( gsm )
                    .name("GPRS").type(typeof(string)).from( this.current_gprs_cipher ).to(gprs ).end();
                    this.current_gsm_cipher = gsm;
                    this.current_gprs_cipher = gprs;
            }
            private void network_incoming_ussd( dynamic DBus.Object obj, string mode, string message )
            {
                this.logger.log("NETWORK").signal("IncomingUSSD")
                    .name( "mode" ).type( typeof(string)).value( mode )
                    .name( "message" ).type( typeof(string) ).value( message ).end();
            }

            private void network_signal_strength_changed(dynamic DBus.Object obj, int i )
            {
                this.logger.log("NETWORK").signal( "SignalStrength" ).name( "strength").type( typeof(int) ).from( this.current_signal_strength.to_string() ).to( i.to_string() ).end();
                this.current_signal_strength = i;
            }

            private void set_signal_strength(dynamic DBus.Object obj, int i, GLib.Error error)
            {
                if( error != null)
                {
                    log("NETWORK", 0, "Can't get signal strength: %s", error.message );
                    this.current_signal_strength = -1;
                }
                else
                {
                    this.current_signal_strength = i;
                }
            }

            private void network_status_changed(dynamic DBus.Object obj, HashTable<string,Value?> properties)
            {
                this.logger.log("NETWORK").signal( "NetworkStatus" ).name( "properties" ).attributes( properties ).end();
            }

        }
        public class PDP: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.Pdp";
            private  HashTable<string,string> current_network_status;
            public PDP( FSO.Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            construct
            {
                this.current_network_status = new HashTable<string,string>(GLib.str_hash, GLib.str_equal );
            }
            public override void run()
            {
                base.run();
                this.object.NetworkStatus += this.pdp_network_status_changed;
                this.object.ContextStatus += this.pdp_context_status_changed;
                try
                {
                    this.object.GetNetworkStatus (this.get_network_status);
                }
                catch (  GLib.Error e )
                {
                    debug( "GetNetworkStatus: %s",e.message );
                }
                debug( "Started GSM.PDP" );

            }
            public override void stop()
            {
                base.stop();
            }
            private void pdp_context_status_changed( dynamic DBus.Object obj, int id, string status, HashTable<string,Value?> properties)
            {
                this.logger.log("PDP").signal( "ContextStatus" )
                    .name( "ID" ).type( typeof(int) ).value( id.to_string() )
                    .name( "status" ).type( typeof(string) ).value( status )
                    .name( "properties").attributes( properties ).end();
            }
            private void get_network_status( dynamic DBus.Object obj, HashTable<string, Value?> status, GLib.Error error)
            {
                if( error != null )
                {
                    debug( "Can't get network status: %s", error.message );
                }
                else
                {
                    status.for_each( (HFunc) get_network_status_to_string );
                }
            }
            private void get_network_status_to_string( string key, Value value)
            {
                this.current_network_status.insert( key, value.get_string() );
            }
            private void pdp_network_status_changed( dynamic DBus.Object obj, HashTable<string, Value?> status )
            {
                this.logger.log("PDP").signal( "NetworkStatus").name("status").attributes( status ).end();
            }

        }
        public class Phone: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Server";
            public static const string IFACE  = "org.freesmartphone.GSM.Phone";
            private string cur_status = null;
            public Phone( FSO.Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.ServiceStatus += this.status_changed;
                debug( "Started GSM.Phone" );
            }
            public override void stop()
            {
                this.object.ServiceStatus -= this.status_changed;
                base.stop();
            }
            private void status_changed( dynamic DBus.Object obj, string status )
            {
                this.logger.log( "GSM:Phone" ).signal( "StatusChanged" ).name( status ).type( typeof( string ) ).from( this.cur_status ).to( status ).end(  );
                this.cur_status = status;
            }
        }
        public class SIM:Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.SIM";

            private string cur_auth_status = null;
            
            public SIM( FSO.Logger l, DBus.Connection c,string name = "")
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.AuthStatus += auth_status_changed;
                this.object.IncomingStoredMessage += incoming_stored_message;
                this.object.ReadyStatus += this.ready_status;
                try
                {
                    this.object.GetAuthStatus ( get_auth_status );
                }
                catch (  GLib.Error e )
                {
                    debug( "GetAuthStatus: %s" , e.message );
                }
                debug( "Started Phone.SIM" );
            }
            public override void stop()
            {
                this.object.AuthStatus -= auth_status_changed;
                this.object.IncomingStoredMessage -= incoming_stored_message;
                base.stop();
            }
            private void auth_status_changed(dynamic DBus.Object obj, string status)
            {
                this.logger.log("SIM" ).signal( "AuthStatus").name("status").type(typeof(string)).from( this.cur_auth_status ).to( status ).end();
                this.cur_auth_status = status;
            }
            private void get_auth_status( dynamic DBus.Object obj, string status, GLib.Error error)
            {
                if( error != null)
                {
                    log( "Can't get authstatus: %s", 0, error.message );
                }
                else
                {
                    this.cur_auth_status = status;
                }
            }
            private void incoming_stored_message( dynamic DBus.Object obj, int idx)
            {
                this.logger.log("SIM").signal("IncomingStoredMessage").name( "index" ).type( typeof(int) ).value( idx.to_string() ).end();
            }
            private void ready_status ( dynamic DBus.Object obj, bool status )
            {
                this.logger.log( "GSM.SIM" ).signal( "ReadyStatus" ).name( "status" ).type( typeof( string ) ).value( status.to_string(  ) ).end( );
            }
        }
        public class SMS: Subsystem
        {
            public static const string OBJ_PATH   = "/org/freesmartphone/GSM/Device";
            public static const string IFACE  = "org.freesmartphone.GSM.SMS";
            public SMS( FSO.Logger l, DBus.Connection c,string name = "" )
            {
                base(l,c,name);
                this._IFACE = IFACE;
                this._OBJ_PATH = OBJ_PATH;
                this._BUS_NAME = BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.IncomingMessage += this.sms_incoming_message;
                debug( "Started Phone.SMS" );

            }
            public override void stop()
            {
                base.stop();
            }
            private void sms_incoming_message(dynamic DBus.Object obj, string sender, string content, HashTable<string,Value?> properties)
            {
                this.logger.log("SMS").signal( "IncomingMessage")
                    .name("sender").type( typeof(string) ).value( sender )
                    .name( "content" ).type( typeof(string) ).value( content )
                    .name( "properties" ).attributes( properties ).end();
            }

        }
    }
}
