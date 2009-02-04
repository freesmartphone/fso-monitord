/*
* monitor.vala
*
* Authored by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//===========================================================================
using GLib;
using CONST;



//===========================================================================
public class Monitor : Object
{
    /*private members*/
    private DBus.Connection conn;
    private Logger logger;

    private dynamic DBus.Object framework;
    private dynamic DBus.Object usage;

    private dynamic DBus.Object ogsmd_device;
    private dynamic DBus.Object ogsmd_sim;
    private dynamic DBus.Object ogsmd_network;
    private dynamic DBus.Object ogsmd_call;
    private dynamic DBus.Object ogsmd_pdp;
    private dynamic DBus.Object ogsmd_cb;
    private dynamic DBus.Object ogsmd_hz;
    private dynamic DBus.Object ogsmd_sms;

    private dynamic DBus.Object ophoned;
    private dynamic DBus.Object ophoned_call;

    private dynamic DBus.Object odeviced;
    private dynamic DBus.Object odeviced_audio;
    private dynamic DBus.Object odeviced_input;
    private dynamic DBus.Object odeviced_power_supply;
    private dynamic DBus.Object odeviced_power_cntl_usb;
    private dynamic DBus.Object odeviced_power_cntl_wifi;
    private dynamic DBus.Object odeviced_power_cntl_bt;

    
    private string current_home_zone;
    private string current_auth_status;
    private string current_gsm_cipher;
    private string current_gprs_cipher;
    private string current_scenario;
    private string current_power_status;
    private string current_capacity;
    private string current_call_status;

    private int current_signal_strength;


    private bool current_power_bt;
    private bool current_power_usb;
    private bool current_power_wifi;

    private HashTable<string,string> current_network_status;

    public Monitor( Logger l )
    {
        this.logger = l;
        this.logger.logINFO( "---------------Monitor restarted----------------" );
    }

    construct
    {
        try
        {
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );

            framework = conn.get_object( FSO_FSO_BUS_NAME, FSO_FSO_OBJ_PATH, FSO_FSO_IFACE );
            debug( "Attached to frameworkd %s. Gathering objects...", framework.GetVersion() );

            debug("Getting usage Object...");

            usage = conn.get_object( FSO_USAGE_BUS_NAME, FSO_USAGE_OBJ_PATH, FSO_USAGE_IFACE );
            usage.ResourceAvailable += this.usage_resource_available;
            usage.ResourceChanged += this.usage_resource_changed;
            usage.SystemAction += this.usage_system_action;

            ogsmd_device = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_DEV_IFACE );
            ogsmd_device.ThisVersionNotThere();

            debug("Getting SIM Object...");
            ogsmd_sim = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SIM_IFACE );
            ogsmd_sim.AuthStatus += this.sim_auth_status_changed;
            ogsmd_sim.GetAuthStatus( this.sim_get_auth_status );
            ogsmd_sim.IncomingStoredMessage += this.sim_incoming_stored_message;
            ogsmd_sim.Ping();

            debug("Getting network Object...");
            ogsmd_network = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_NET_IFACE );
            ogsmd_network.Status += this.network_status_changed;
            ogsmd_network.SignalStrength += this.network_signal_strength_changed;
            ogsmd_network.GetSignalStrength( this.set_signal_strength );
            ogsmd_network.IncomingUssd += this.network_incoming_ussd;
            ogsmd_network.CipherStatus += this.cipher_status_changed;
            ogsmd_network.Ping();

            debug("Getting call Object...");
            ogsmd_call = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CALL_IFACE );
            ogsmd_call.CallStatus += this.call_status_changed;
            ogsmd_call.ListCalls(this.set_call_state);
            ogsmd_call.Ping();

            debug("Getting pdp Object...");
            ogsmd_pdp = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_PDP_IFACE );
            ogsmd_pdp.NetworkStatus += this.pdp_network_status_changed;
            ogsmd_pdp.GetNetworkStatus (this.get_network_status);
            ogsmd_pdp.ContextStatus += this.pdp_context_status_changed;
            ogsmd_pdp.Ping();

            debug("Getting cb Object...");
            ogsmd_cb = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CB_IFACE );
            ogsmd_cb.IncomingCellBroadcast += this.incoming_cb;
            ogsmd_cb.Ping();

            debug("Getting sms Object...");
            ogsmd_sms = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SMS_IFACE );
            ogsmd_sms.IncomingMessage += this.sms_incoming_message;
            ogsmd_sms.Ping();

            debug("Getting usage Object...");
            odeviced_audio = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_AUDIO_OBJ_PATH, FSO_DEV_AUDIO_IFACE );
            odeviced_audio.SoundStatus += this.sound_status_changed;
            odeviced_audio.Scenario += this.scenario_changed;
            odeviced_audio.GetScenario ( this.get_scenario );
            odeviced_audio.Ping();

            debug("Getting input Object...");
            odeviced_input = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_INPUT_OBJ_PATH, FSO_DEV_INPUT_IFACE );
            odeviced_input.Event += this.input_event;
            odeviced_input.Ping();

            debug("Getting PowerControl.USB Object...");
            odeviced_power_cntl_usb = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_USB_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_usb.GetPower( this.get_power_usb );
            odeviced_power_cntl_usb.Power += this.power_changed_usb;
            odeviced_power_cntl_usb.Ping();

            debug("Getting PowerControl.Wifi Object...");
            odeviced_power_cntl_wifi = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_WIFI_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_wifi.GetPower( this.get_power_wifi );
            odeviced_power_cntl_wifi.Power += this.power_changed_wifi;
            odeviced_power_cntl_wifi.Ping();

            debug("Getting PowerControl.BT Object...");
            odeviced_power_cntl_bt = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_BT_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_bt.GetPower( this.get_power_bt );
            odeviced_power_cntl_bt.Power += this.power_changed_bt;
            odeviced_power_cntl_bt.Ping();

            debug("Getting PowerSupply Object...");
            odeviced_power_supply = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_POWER_SUPPLY_OBJ_PATH, FSO_DEV_POWER_SUPPLY_IFACE );
            odeviced_power_supply.PowerStatus += this.power_status_changed;
            odeviced_power_supply.GetPowerStatus( this.get_power_status );
            odeviced_power_supply.Capacity += this.capacity_changed;
            odeviced_power_supply.GetCapacity( this.get_capacity );
            odeviced_power_supply.Ping();

            debug("Getting HZ Object...");
            // HZ is exported by org/freesmartphone/GSM/Server
            ogsmd_hz = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_PHONE_OBJ_PATH, FSO_GSM_HZ_IFACE );
            ogsmd_hz.HomeZoneStatus += this.home_zone_changed;
            ogsmd_hz.GetHomeZoneStatus(this.get_home_zone);
            ogsmd_hz.Ping();


            //ogsmd_monitor = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_MON_IFACE );
            //ogsmd_monitor.Ping();

            debug( "... done." );
            this.current_network_status = new HashTable<string,string>(GLib.str_hash, GLib.str_equal );
            this.current_gsm_cipher = "unknown";
            this.current_gprs_cipher = "unknown";


        } catch (DBus.Error e) {
            error( e.message );
        }
    }
    //
    //org.freedesktop.Device.Audio
    //
    private void sound_status_changed( dynamic DBus.Object obj, string id, string status, HashTable<string,Value?> properties )
    {
        this.logger.log("DEVICE").signal("Status").name("ID").type(typeof(string)).value(id).name("status").type(typeof(string)).value(status);
        //ignoring properties: not yet defined
    }
    private void scenario_changed( dynamic DBus.Object obj, string scenario)
    {
        this.logger.log("DEVICE").signal( "Scenario changed").name( "scenario").type(typeof(string)).from( this.current_scenario ).to(  scenario ).end();
        this.current_scenario = scenario;
    }
    private void get_scenario( dynamic DBus.Object obj, string s, GLib.Error error )
    {
        if( error != null )
        {
            debug("Can't get scenario: %s" , error.message );
            this.current_scenario = "UNKNOWN";
        }
        else
        {
            this.current_scenario = s;
        }
    }

    //
    //org.freedesktop.Device.Input
    //
    private void input_event( dynamic DBus.Object obj, string name, string action, int seconds)
    {
        this.logger.log("DEVICE").signal( "Event" )
            .name("name").type( typeof(string) ).value( name )
            .name( "action" ).type( typeof(string) ).value( action )
            .name("seconds").type(typeof(int)).value( seconds.to_string()).end();
    }

    //
    //org.freesmartphone.Device.PowerControl
    //
    private void power_changed_usb( dynamic DBus.Object obj, bool on)
    {
        this.logger.log("DEVICE").signal( "USBPower" ).name( "on" ).from( this.current_power_usb.to_string() ).to( on.to_string()).end();    
        this.current_power_usb = on;
    }

    private void get_power_usb( dynamic DBus.Object obj, bool on, GLib.Error error)
    {
        if( error != null )
        {
            debug("Can't get USB Power %s", error.message );
            //Let's say no to have a defined state
            this.current_power_usb = false;
        }
        else
        {
            this.current_power_usb = on;
        }
        
    }

    private void power_changed_wifi( dynamic DBus.Object obj, bool on)
    {
        this.logger.log("DEVICE").signal( "WiFiPower" ).name( "on").type(typeof(bool) ).from( this.current_power_wifi.to_string() ).to( on.to_string()).end();    
        this.current_power_wifi = on;
    }

    private void get_power_wifi( dynamic DBus.Object obj, bool on, GLib.Error error)
    {
        if( error != null )
        {
            debug("Can't get Power %s", error.message );
            //Let's say no to have a defined state
            this.current_power_wifi = false;
        }
        else
        {
            this.current_power_wifi = on;
        }
        
    }

    private void power_changed_bt( dynamic DBus.Object obj, bool on)
    {
        this.logger.log("DEVICE").signal( "Bluetooth Power" ).name( "on" ).type( typeof( bool ) ).from( this.current_power_bt.to_string() ).to( on.to_string()).end();    
        this.current_power_bt = on;
    }

    private void get_power_bt( dynamic DBus.Object obj, bool on, GLib.Error error)
    {
        if( error != null )
        {
            debug("Can't get Bluetooth Power %s", error.message );
            //Let's say no to have a defined state
            this.current_power_bt = false;
        }
        else
        {
            this.current_power_bt = on;
        }
        
    }

    //
    //org.freedesktop.Device.PowerSupply 
    //
    private void power_status_changed( dynamic DBus.Object obj, string status)
    {
        this.logger.log( "POWERSUPPLY" ).signal( "PowerStatus").name( "status" ).type(typeof(string) ).from( this.current_power_status).to( status ).end();
        this.current_power_status = status;
    }
    private void get_power_status( dynamic DBus.Object obj, string status, GLib.Error error)
    {
        if( error != null )
        {
            debug( "Can't get power status: %s", error.message );
            this.current_power_status = "unknown";
        }
        else
        {
            this.current_power_status = status;
        }
    }
    private void capacity_changed( dynamic DBus.Object obj, string status )
    {
        this.logger.log( "POWERSUPPLY" ).name( "CapacityChanged" ).type(typeof(string)).from(this.current_capacity).to( status ).end();
        this.current_capacity = status;
    }

    private void get_capacity( dynamic DBus.Object obj, string capacity, GLib.Error error )
    {
        if ( error != null )
        {
            debug("Can't get capacity: %s", error.message );
            this.current_capacity = "UNKNOWN";
        }
        else
        {
            this.current_capacity = capacity;
        }
    }

    //
    // org.freesmartphone.Usage
    //
    private void usage_resource_available( dynamic DBus.Object obj, string name, bool state)
    {
        this.logger.log("USAGE").signal( "ResourceAvailable" )
            .name("name").type( typeof(string)).value( name )
            .name( "state" ).type(typeof(bool)).value( state.to_string() ).end();
    }
    private void usage_resource_changed( dynamic DBus.Object obj, string name, bool state, HashTable<string, Value?> attr)
    {
        this.logger.log("USAGE").signal( "RessourceChanged:")
            .name( "name").type(typeof(string)).value( name )
            .name( "state").type( typeof(string)).value(state.to_string())
            .name( "attributes" ).attributes( attr ).end();
    }

    private void usage_system_action(dynamic DBus.Object obj, string action)
    {
        this.logger.log("USAGE").signal( "SystemAction" ).name( "action" ).type( typeof( string ) ).value( action).end();
    }

    //
    // org.freesmartphone.GSM.SMS
    //
    private void sms_incoming_message(dynamic DBus.Object obj, string sender, string content, HashTable<string,Value?> properties)
    {
        this.logger.log("SMS").signal( "IncomingMessage")
            .name("sender").type( typeof(string) ).value( sender )
            .name( "content" ).type( typeof(string) ).value( content )
            .name( "properties" ).attributes( properties ).end();
    }

    //
    // org.freesmartphone.GSM.SIM
    //
    private void sim_auth_status_changed(dynamic DBus.Object obj, string status)
    {
        this.logger.log("SIM" ).signal( "AuthStatus").name("status").type(typeof(string)).from( this.current_auth_status ).to( status ).end();
        this.current_auth_status = status;
    }
    private void sim_get_auth_status( dynamic DBus.Object obj, string status, GLib.Error error)
    {
        if( error != null)
        {
            log( "Can't get authstatus: %s", 0, error.message );
        }
        else
        {
            this.current_auth_status = status;
            this.logger.log( "SIM" ).signal( "AuthStatus").name( "status" ).type( typeof(string) ).value( status ).end();
        }
    }
    private void sim_incoming_stored_message( dynamic DBus.Object obj, int idx)
    {
        this.logger.log("SIM").signal("IncomingStoredMessage").name( "index" ).type( typeof(int) ).value( idx.to_string() ).end();
    }

    //
    // org.freesmartphone.GSM.PDP
    //
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
        this.logger.log("PDP").signal( "NetworkStatus").name("status").attributes( status );
    }

    //
    // org.freesmartphone.GSM.HZ
    //
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

    //
    // org.freesmartphone.GSM.Network
    //
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


    //
    // org.freesmartphone.GSM.Call
    //
    public void call_status_changed( dynamic DBus.Object obj, int id,
            string status, GLib.HashTable<string,Value?> properties)
    {
        this.logger.log("CALL").signal( "Status" )
                .name( "ID" ).type( typeof( int) ).value( id.to_string() )
                .name( "status").type ( typeof( string ) ).value( status )
                .name( "properties" ).attributes( properties ).end();
    }
    private void set_call_state( dynamic DBus.Object obj, int serial,
            string status, GLib.HashTable<string,Value?> properties, GLib.Error error)
    {
        if( error != null)
        {
            log("CALL", 0, "Can't get current CallStatus %s", error.message);
            this.current_call_status = "UNKOWN";
        }
        else
        {
            this.current_call_status = status;
        }
    }

    //
    // org.freesmartphone.GSM.CB
    //
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

    //
    // org.freedesktop.Gypsy.Accuracy
    //
    public void accuracy_changed(DBus.Object obj, int fields, double pdop, double hdop, double vdop)
    {
        this.logger.log("GPS").signal( "AccuracyChanged" )
                .name( "fields" ).type( typeof( int ) ).value( fields.to_string() )
                .name( "pdop" ).type( typeof( double ) ).value( pdop.to_string() )
                .name( "pdop" ).type( typeof( double ) ).value( hdop.to_string() )
                .name( "pdop" ).type( typeof( double ) ).value( vdop.to_string() ).end();
    }
}

