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
    DBus.Connection conn;
	Logger logger;

    dynamic DBus.Object framework;
    //dynamic DBus.Object testing;
    dynamic DBus.Object usage;

    dynamic DBus.Object ogsmd_device;
    dynamic DBus.Object ogsmd_sim;
    dynamic DBus.Object ogsmd_network;
    dynamic DBus.Object ogsmd_call;
    dynamic DBus.Object ogsmd_pdp;
    dynamic DBus.Object ogsmd_cb;
    dynamic DBus.Object ogsmd_hz;
    //dynamic DBus.Object ogsmd_monitor;
    dynamic DBus.Object ogsmd_sms;
    dynamic DBus.Object ophoned;
    dynamic DBus.Object ophoned_call;

    
    string current_call_status;
    string current_idle_status;
    string current_home_zone;
    string current_auth_status;
	string current_gsm_cipher;
	string current_gprs_cipher;
    //string current_context_status;
    int current_signal_strength;

	HashTable<string,string> current_network_status;



    construct
    {
        try
        {
			logger = new Logger();
            debug( "---------------Monitor restarted----------------" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );

            framework = conn.get_object( FSO_FSO_BUS_NAME, FSO_FSO_OBJ_PATH, FSO_FSO_IFACE );
            debug( "attached to frameworkd %s. Gathering objects...", framework.GetVersion() );

            
            usage = conn.get_object( FSO_USAGE_BUS_NAME, FSO_USAGE_OBJ_PATH, FSO_USAGE_IFACE );
            usage.ResourceAvailable += this.usage_resource_available;
            usage.ResourceChanged += this.usage_resource_changed;
            usage.SystemAction += this.usage_system_action;
            

            //testing = conn.get_object( FSO_TEST_BUS_NAME, FSO_TEST_OBJ_PATH, FSO_TEST_IFACE );

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

            ogsmd_hz = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_HZ_IFACE );
            ogsmd_hz.HomeZoneStatus += this.home_zone_changed;
            ogsmd_hz.GetHomeZoneStatus(this.get_home_zone);
            ogsmd_hz.Ping();

            ogsmd_sms = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SMS_IFACE );
            ogsmd_sms.IncomingMessage += this.sms_incoming_message;
            ogsmd_sms.Ping();


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
    //GSM.Usage--------------------------------------------------------------------
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
        

    //GSM.SMS----------------------------------------------------------------------
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
    //GSM.SIM----------------------------------------------------------------------
    private void sim_auth_status_changed(dynamic DBus.Object obj, string status)
    {
        log("SIM", 0, "Auth status changed: %s -> %s", this.current_auth_status, status);
        this.current_auth_status = status;
    }
    private void sim_get_auth_status( dynamic DBus.Object obj, string status, GLib.Error error)
    {
		string msg = null;
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
    //GSM.PDP----------------------------------------------------------------------
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
            log("PDP",0, "Status");
            status.for_each((HFunc) log_pdp_network_status );
        }
    }
    private void log_pdp_network_status( string key, Value value)
    {
		string val = this.current_network_status.lookup( key );
		string msg = null;
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

    //GSM.HZ-----------------------------------------------------------------------
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
    //GSM.Network ------------------------------------------------------------------
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

    //GSM.Call----------------------------------------------------------------------
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
    //GSM.CB-----------------------------------------------------------------------
    private void incoming_cb(dynamic DBus.Object obj, int serial, int channel, 
            int encoding, int page, string data)
    {
        log("CB", 0,"Received CB with serial %i on channel %i. Encoding %i Page: %i Data: %s", 
            serial,channel, encoding, page,data);
    }
    //GPS----------------------------------------------------------------------

    public void accuracy_changed(DBus.Object obj)
    {
        log("GPS", 0,"Accuracy changed");
    }
    //IdleState-----------------------------------------------------------------
    public void idle_state_changed(DBus.Object obj, string status)
    {
        log("IdleNotifier", 0,"State changed: %s -> %s",this.current_idle_status, status);
        this.current_idle_status = status;
    }
 }

