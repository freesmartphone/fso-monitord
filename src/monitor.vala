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
string[] stringListToArray( List<string>? theList )
{
    var res = new string[theList.length()];
    int counter = 0;
    foreach ( string el in theList )
    {
        res[counter] = el;
        counter++;
    }
    return res;
}

string value_to_string( Value value )
{
    string val = null;
    if( value.holds( typeof( string ) ) )
    {
        val = value.get_string() ;
    }
    else if (value.holds( typeof( int ) ) )
    {
        val = value.get_int( ).to_string();
    }
    else if (value.holds( typeof( bool ) ) )
    {
        val = value.get_boolean().to_string();
    }
    else if( value.holds( typeof( uint ) ) )
    {
        val = value.get_uint().to_string();
    }
    else if( value.holds( typeof( double ) ) )
    {
        val = value.get_double().to_string();
    }
    else if( value.holds( typeof( float ) ) )
    {
        val = value.get_float().to_string();
    }
    else if( value.holds( typeof( char ) ) )
    {
        val = value.get_char().to_string();
    }
    else
    {
        val = "unknown type: " + value.type_name();
    }

    return val;
}


//===========================================================================
public class Monitor : Object
{
    /*private members*/
    private DBus.Connection conn;
    private Logger logger;

    private dynamic DBus.Object framework;
    private dynamic DBus.Object usage;
    private dynamic DBus.Object powersupply;

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

    
    private string current_call_status;
    private string current_home_zone;
    private string current_auth_status;
    private string current_gsm_cipher;
    private string current_gprs_cipher;
    private string current_scenario;
    private string current_power_status;

    private int current_signal_strength;
    private int current_capacity;


    private bool current_power_bt;
    private bool current_power_usb;
    private bool current_power_wifi;

    private HashTable<string,string> current_network_status;

    public Monitor( Logger l )
    {
        this.logger = l;
        logger.logINFO( "---------------Monitor restarted----------------" );
    }

    construct
    {
        try
        {
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );

            framework = conn.get_object( FSO_FSO_BUS_NAME, FSO_FSO_OBJ_PATH, FSO_FSO_IFACE );
            debug( "Attached to frameworkd %s. Gathering objects...", framework.GetVersion() );

            usage = conn.get_object( FSO_USAGE_BUS_NAME, FSO_USAGE_OBJ_PATH, FSO_USAGE_IFACE );
            usage.ResourceAvailable += this.usage_resource_available;
            usage.ResourceChanged += this.usage_resource_changed;
            usage.SystemAction += this.usage_system_action;

            powersupply = conn.get_object( FSO_DEV_BUS_NAME, FSO_DEV_POWER_SUPPLY_OBJ_PATH, FSO_DEV_POWER_SUPPLY_IFACE );
            powersupply.Status += this.powersupply_status;
            powersupply.Capacity += this.powersupply_capacity;

            ogsmd_device = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_DEV_IFACE );
            ogsmd_device.ThisVersionNotThere();

            ogsmd_sim = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SIM_IFACE );
            ogsmd_sim.AuthStatus += this.sim_auth_status_changed;
            ogsmd_sim.GetAuthStatus( this.sim_get_auth_status );
            ogsmd_sim.IncomingStoredMessage += this.sim_incoming_stored_message;
            ogsmd_sim.Ping();

            ogsmd_network = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_NET_IFACE );
            ogsmd_network.Status += this.network_status_changed;
            ogsmd_network.SignalStrength += this.network_signal_strength_changed;
            ogsmd_network.GetSignalStrength( this.set_signal_strength );
            ogsmd_network.IncomingUssd += this.network_incoming_ussd;
            ogsmd_network.CipherStatus += this.cipher_status_changed;
            ogsmd_network.Ping();

            ogsmd_call = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CALL_IFACE );
            ogsmd_call.CallStatus += this.call_status_changed;
            ogsmd_call.ListCalls(this.set_call_state);
            ogsmd_call.Ping();

            ogsmd_pdp = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_PDP_IFACE );
            ogsmd_pdp.NetworkStatus += this.pdp_network_status_changed;
            ogsmd_pdp.GetNetworkStatus (this.get_network_status);
            ogsmd_pdp.ContextStatus += this.pdp_context_status_changed;
            ogsmd_pdp.Ping();

            ogsmd_cb = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CB_IFACE );
            ogsmd_cb.IncomingCellBroadcast += this.incoming_cb;
            ogsmd_cb.Ping();

            ogsmd_sms = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SMS_IFACE );
            ogsmd_sms.IncomingMessage += this.sms_incoming_message;
            ogsmd_sms.Ping();

            odeviced_audio = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_AUDIO_OBJ_PATH, FSO_DEV_AUDIO_IFACE );
            odeviced_audio.SoundStatus += this.sound_status_changed;
            odeviced_audio.Scenario += this.scenario_changed;
            odeviced_audio.GetScenario ( this.get_scenario );
            odeviced_audio.Ping();

            odeviced_input = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_INPUT_OBJ_PATH, FSO_DEV_INPUT_IFACE );
            odeviced_input.Event += this.input_event;
            odeviced_input.Ping();

            odeviced_power_cntl_usb = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_USB_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_usb.GetPower( this.get_power_usb );
            odeviced_power_cntl_usb.Power += this.power_changed_usb;
            odeviced_power_cntl_usb.Ping();

            odeviced_power_cntl_usb = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_WIFI_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_wifi.GetPower( this.get_power_wifi );
            odeviced_power_cntl_wifi.Power += this.power_changed_wifi;
            odeviced_power_cntl_wifi.Ping();

            odeviced_power_cntl_usb = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_PC_BT_OBJ_PATH, FSO_DEV_POWER_CONTROL_IFACE );
            odeviced_power_cntl_bt.GetPower( this.get_power_bt );
            odeviced_power_cntl_bt.Power += this.power_changed_bt;
            odeviced_power_cntl_wifi.Ping();


            odeviced_power_supply = conn.get_object (FSO_DEV_BUS_NAME, FSO_DEV_POWER_SUPPLY_OBJ_PATH, FSO_DEV_POWER_SUPPLY_IFACE );
            odeviced_power_supply.PowerStatus += this.power_status_changed;
            odeviced_power_supply.GetPowerStatus( this.get_power_status );
            odeviced_power_supply.Capacity += this.capacity_changed;
            odeviced_power_supply.GetCapacity( this.get_capacity );
            odeviced_power_supply.Ping();
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
        logger.log("DEVICE.AUDIO", "Status :" + id + ": " + status);
        //ignoring properties: not yet defined
    }
    private void scenario_changed( dynamic DBus.Object obj, string scenario)
    {
        logger.log("DEVICE.AUDIO", "Scenario changed: " + this.current_scenario + "->" + scenario);
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
        logger.log("DEVICE.INPUT", "Event: " + name + action + seconds.to_string());    
    }

    //
    //org.freesmartphone.Device.PowerControl
    //
    private void power_changed_usb( dynamic DBus.Object obj, bool on)
    {
        logger.log("DEVICE", "USB Power: " + this.current_power_usb.to_string() + "->" + on.to_string());    
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
        logger.log("DEVICE", "WiFi Power: " + this.current_power_wifi.to_string() + "->" + on.to_string());    
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
        logger.log("DEVICE", "Bluetooth Power: " + this.current_power_bt.to_string() + "->" + on.to_string());    
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
        logger.log( "POWERSUPPLY", "PowerStatus changed" + this.current_power_status + "->" + status );
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
    private void capacity_changed( dynamic DBus.Object obj, int status )
    {
        logger.log( "POWERSUPPLY", "Capacity changed: " + this.current_capacity.to_string() + "->" + status.to_string() );
        this.current_capacity = status;
    }
    private void get_capacity( dynamic DBus.Object obj, int capacity, GLib.Error error )
    {
        if ( error != null )
        {
            debug("Can't get capacity: %s", error.message );
            this.current_capacity = -1;
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
        logger.log("USAGE", "Resource available: name:'" + name + "' state: " + state.to_string() );
    }
    private void usage_resource_changed( dynamic DBus.Object obj, string name, bool state, HashTable<string, Value?> attr)
    {
        logger.log("USAGE", "Ressource Changed: name: '" + name +"' state: " +state.to_string());
        if(attr != null)
        {
            this.logger.log("USAGE", "Attributes:");
            attr.for_each((HFunc) log_usage_resource_changed_attr);
        }
    }
    private void log_usage_resource_changed_attr(string key, Value value)
    {
        this.logger.log( "USAGE", key + ": " + value_to_string(value) );
    }

    private void usage_system_action(dynamic DBus.Object obj, string action)
    {
        this.logger.log("USAGE", "System action: " + action);
    }

    //
    // org.freesmartphone.Device
    //
    private void powersupply_status( dynamic DBus.Object obj, string status )
    {
        logger.log("DEVICE", "Power Status: " + status );
    }
    private void powersupply_capacity( dynamic DBus.Object obj, int capacity )
    {
        logger.log("DEVICE", "Power Capacity: " + capacity.to_string() );
    }

    //
    // org.freesmartphone.GSM.SMS
    //
    private void sms_incoming_message(dynamic DBus.Object obj, string sender, string content, HashTable<string,Value?> properties)
    {
        this.logger.log("SMS", "Incoming message. sender:" + sender + "content: " + content );
        if( properties != null)
        {
            this.logger.log("SMS", "Properties:");
            properties.for_each((HFunc)log_sms_incoming_properties);
        }
    }
    private void log_sms_incoming_properties( string key, Value value )
    {
        this.logger.log( "SMS", key + ": " + value_to_string(value) );
    }

    //
    // org.freesmartphone.GSM.SIM
    //
    private void sim_auth_status_changed(dynamic DBus.Object obj, string status)
    {
        logger.log("SIM", "Auth status changed: " +  this.current_auth_status + "->" + status);
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
            this.logger.log( "SIM", "New authstatus: " + status );
        }
    }
    private void sim_incoming_stored_message( dynamic DBus.Object obj, int idx)
    {
        this.logger.log("SIM", "New stored message at " + idx.to_string() );
    }

    //
    // org.freesmartphone.GSM.PDP
    //
    private void pdp_context_status_changed( dynamic DBus.Object obj, int id, string status, HashTable<string,Value?> properties)
    {
        this.logger.log("PDP", "Context status changed. ID: "+ id.to_string() + " status: " +status );
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
        logger.log("PDP", "Network Status changed");
        if(status != null)
        {
            logger.log("PDP", "Status");
            status.for_each((HFunc) log_pdp_network_status );
        }
    }
    private void log_pdp_network_status( string key, Value value)
    {
        string val = this.current_network_status.lookup( key );
        string sval =  value.get_string() ;

        if( val == null )
        {
            this.current_network_status.insert(key, sval );
            this.logger.log("PDP", "New Status " + key + ": " + sval );
        }
        else if( val != value.get_string() )
        {
            this.current_network_status.replace(key, sval );
            this.logger.log("PDP", "Status changed: " + key + " " + val + "->" + sval );
        }
        //How could we figure out if an element is gone?
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
            this.logger.log("HZ", "Current homezone: " + zone );
            this.current_home_zone = zone;
        }
    }

    private void home_zone_changed( dynamic GLib.Object obj, string zone)
    {
        this.logger.log("HZ", "Homezone changed: " + this.current_home_zone + "->" + zone);
        this.current_home_zone = zone;
    }

    //
    // org.freesmartphone.GSM.Network
    //
    private void cipher_status_changed(dynamic DBus.Object obj, string gsm, string gprs )
    {
        this.logger.log("NETWORK", "Cipher status changed. GSM: " + this.current_gsm_cipher + "->" + gsm + " GPRS: " + this.current_gprs_cipher + "->" + gprs );
    }
    private void network_incoming_ussd( dynamic DBus.Object obj, string mode, string message )
    {
        this.logger.log("NETWORK", "Incoming USSD. mode: " + mode + " message: " + message );
    }

    private void network_signal_strength_changed(dynamic DBus.Object obj, int i )
    {
        this.logger.log("NETWORK", "Signal strength changed: " + this.current_signal_strength.to_string() + "%%->" + i.to_string() );
        this.current_signal_strength = i;
    }

    private void set_signal_strength(dynamic DBus.Object obj, int i, GLib.Error error)
    {
        if( error != null)
        {
            log("NETWORK", 0, "Can't get signal strength: %s", error.message );
        }
        else
        {
            this.current_signal_strength = i;
        }
    }

    private void network_status_changed(dynamic DBus.Object obj, HashTable<string,Value?> properties)
    {
        this.logger.log("NETWORK",  "GSM Network status changed");
        if( properties != null)
        {
            logger.log("NETWORK", "Properties");
            properties.for_each( (HFunc) this.log_nw_status_properties);
        }

    }

    private void log_nw_status_properties( string key, Value value)
    {
        logger.log("NETWORK", key + ": " + value_to_string(value) );
    }

    //
    // org.freesmartphone.GSM.Call
    //
    public void call_status_changed( dynamic DBus.Object obj, int id,
            string status, GLib.HashTable<string,Value?> properties)
    {
        this.logger.log("CALL", "Status changed to: " + this.current_call_status + " -> " + status + " ID: " +id.to_string() );
        if(properties != null)
        {
            this.logger.log("CALL", "Properties:" );
            properties.for_each((HFunc)this.log_call_status_properties);
        }
        this.current_call_status = status;
    }
    private void log_call_status_properties(string key, Value value)
    {
        //currently all parameters are strings
        logger.log("CALL", key + ": " + value.get_string());
    }
    private void set_call_state( dynamic DBus.Object obj, int serial,
            string status, GLib.HashTable<string,Value?> properties, GLib.Error error)
    {
        if( error != null)
        {
            log("CALL", 0, "Can't get current CallStatus %s", error.message);
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
        logger.log("CB", "Received CB with serial " +  serial.to_string() + "on channel " + channel.to_string() +". Encoding " +encoding.to_string() + " Page: " + " Data: " + data);
        log("CB", 0,"Received CB with serial %i on channel %i. Encoding %i Page: %i Data: %s",
            serial,channel, encoding, page,data);
    }

    //
    // org.freedesktop.Gypsy.Accuracy
    //
    public void accuracy_changed(DBus.Object obj)
    {
        logger.log("GPS", "Accuracy changed");
    }
 }
}

