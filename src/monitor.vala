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


//===========================================================================
public class Monitor : Object
{
    /*private members*/
    DBus.Connection conn;

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
    //string current_context_status;
    int current_signal_strength;


    construct
    {
        try
        {
            debug( "monitor object created" );
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

        } catch (DBus.Error e) {
            error( e.message );
        }
    }
	//GSM.Usage--------------------------------------------------------------------
	private void usage_resource_available( dynamic DBus.Object obj, string name, bool state)
	{
		log("USAGE", 0, "Resource available: name:'%s' state:%s", name, state.to_string());
	}
	private void usage_resource_changed( dynamic DBus.Object obj, string name, bool state, HashTable<string, Value?> attr)
	{
		log("USAGE", 0, "Ressource Changed: name:'%s' state:%s", name, state.to_string());
		if(attr != null)
		{
			log("USAGE", 0, "Attributes:");
			attr.for_each((HFunc) log_usage_resource_changed_attr);
		}
	}
	private void log_usage_resource_changed_attr(string key, Value value)
	{
        if( value.holds( typeof( string ) ) )
        {
            log( "USAGE", 0, "%s: %s", key, value.get_string() );
        }
        else if (value.holds( typeof( int ) ) )
        {
            log( "USAGE", 0, "%s: %i", key, value.get_int() );
        }
        else if (value.holds( typeof( bool ) ) )
        {
            log( "USAGE", 0, "%s: %s", key, value.get_boolean().to_string() );
        }
		
        else
        {
            log( "USAGE", 0, "%s has unknown type: %s", key, value.type_name() );
        }
    }
	private void usage_system_action(dynamic DBus.Object obj, string action)
	{
		log("USAGE", 0, "System action: %s", action);
	}
		

    //GSM.SMS----------------------------------------------------------------------
    private void sms_incoming_message(dynamic DBus.Object obj, string sender, string content, HashTable<string,Value?> properties)
    {
        log("SMS", 0, "Incoming message. sender: %s content: %s", sender, content );
		if( properties != null)
		{
			log("SMS", 0,"Properties:");
        	properties.for_each((HFunc)log_sms_incoming_properties);
		}
    }
    private void log_sms_incoming_properties( string key, Value value )
    {
        if( value.holds( typeof( string ) ) )
        {
            log( "SMS", 0, "%s: %s", key, value.get_string() );
        }
        else if (value.holds( typeof( int ) ) )
        {
            log( "SMS", 0, "%s: %i", key, value.get_int() );
        }
        else
        {
            log( "SMS", 0, "%s has unknown type: %s", key, value.type_name() );
        }
    }
    //GSM.SIM----------------------------------------------------------------------
    private void sim_auth_status_changed(dynamic DBus.Object obj, string status)
    {
        log("SIM", 0, "Auth status changed: %s -> %s", this.current_auth_status, status);
        this.current_auth_status = status;
    }
    private void sim_get_auth_status( dynamic DBus.Object obj, string status, GLib.Error error)
    {
        if( error != null)
        {
            log("SIM", 0, "Can't get authstatus: %s", error.message );
        }
        else
        {
            log("SIM", 0, "New authstatus: %s", status );
            this.current_auth_status = status;
        }
    }
    private void sim_incoming_stored_message( dynamic DBus.Object obj, int idx)
    {
        log("SIM", 0, "New stored message at %i", idx);
    }
    //GSM.PDP----------------------------------------------------------------------
    private void pdp_context_status_changed( dynamic DBus.Object obj, int id, string status, HashTable<string,Value?> properties)
    {
        log("PDP", 0, "Context status changed. ID: %i status: %s", id, status);
		if( properties != null)
		{
        	log("PDP", 0, "Properties:");
        	properties.for_each((HFunc) log_pdp_context_properties);
		}
    }
    private void log_pdp_context_properties( string key, Value value)
    {
        log("PDP",0 ,"%s: %s", key, value.get_string( ) );
    }
    private void pdp_network_status_changed( dynamic DBus.Object obj, HashTable<string, Value?> status )
    {
        log("PDP", 0, "Network Status changed");
		if(status != null)
		{
			log("PDP",0, "Status");
        	status.for_each((HFunc) log_pdp_network_status );
		}
    }
    private void log_pdp_network_status( string key, Value value)
    {
        log("PDP", 0, "%s : %s", key, value.get_string() );
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
            log("HZ", 0, "Current homezone: %s", zone );
            this.current_home_zone = zone;
        }
    }

    private void home_zone_changed( dynamic GLib.Object obj, string zone)
    {
        log("HZ", 0, "Homezone changed: %s -> %s", this.current_home_zone, zone);
    }
    //GSM.Network ------------------------------------------------------------------
    private void cipher_status_changed(dynamic DBus.Object obj, string gsm, string gprs )
    {
        log("Network", 0, "Cipher status changed. GSM: %s GPRS: %s", gsm, gprs );
    }
    private void network_incoming_ussd( dynamic DBus.Object obj, string mode, string message )
    {
        log("Network", 0, "Incoming USSD. mode: %s message: %s", mode, message );
    }

    private void network_signal_strength_changed(dynamic DBus.Object obj, int i )
    {
        log("Network", 0, "Signal strength changed: %i%% -> %i%%", this.current_signal_strength, i);
        this.current_signal_strength = i;
    }

    private void set_signal_strength(dynamic DBus.Object obj, int i, GLib.Error error)
    {
        if( error != null)
        {
            log("Network", 0, "Can't get signal strength: %s", error.message );
        }
        else
        {
            this.current_signal_strength = i;
        }
    }

    private void network_status_changed(dynamic DBus.Object obj, HashTable<string,Value?> properties)
    {
        log("Network", 0, "Status changed");
		if( properties != null)
		{
			log("Network", 0, "Properties");
        	properties.for_each( (HFunc) this.log_nw_status_properties);
		}

    }

    private void log_nw_status_properties( string key, Value value)
    {
        if( value.holds( typeof( string ) ) )
        {
            log( "Network", 0, "%s: %s", key, value.get_string() );
        }
        else if (value.holds( typeof( int ) ) )
        {
            log( "Network", 0, "%s: %i", key, value.get_int() );
        }
        else
        {
            log( "Network", 0, "%s has unknown type: %s", key, value.type_name() );
        }


    }

    //GSM.Call----------------------------------------------------------------------
    public void call_status_changed( dynamic DBus.Object obj, int id,  
            string status, GLib.HashTable<string,Value?> properties)
    {
        log("Call",0,"Status changed to: %s -> %s ID:%i", this.current_call_status, status, id );
		if(properties != null)
		{
        	log("Call",0,"Properties:");
        	properties.for_each((HFunc)this.log_call_status_properties);
		}
        this.current_call_status = status;    
    }
    private void log_call_status_properties(string key, Value value)
    {
        //currently all parameters are strings
        log("Call", 0, "%s: %s", key, value.get_string());
    }
    private void set_call_state( dynamic DBus.Object obj, int serial, 
            string status, GLib.HashTable<string,Value?> properties, GLib.Error error)
    {
        if( error != null)
        {
            log("Call", 0, "Can't get current CallStatus %s", error.message);
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

