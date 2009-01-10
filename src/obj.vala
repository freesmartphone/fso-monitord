/*
 * obj.vala
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
public class Logger : Object
{
    public Logger()
    {
    }

    // Signals with complex types do not work yet :/ See
    // http://mail.gnome.org/archives/vala-list/2009-January/msg00033.html
    public void testing_test( dynamic DBus.Object sender, HashTable<string,Value?> foo )
    {
        debug( "message" );
    }

    public void network_status()
    {
        debug( "gsm: network_status" );
    }

}


//===========================================================================
public class Monitor : Object
{
    DBus.Connection conn;

    dynamic DBus.Object framework;
    dynamic DBus.Object testing;
    dynamic DBus.Object usage;

    dynamic DBus.Object ogsmd_device;
    dynamic DBus.Object ogsmd_sim;
    dynamic DBus.Object ogsmd_network;
    dynamic DBus.Object ogsmd_call;
    dynamic DBus.Object ogsmd_pdp;
    dynamic DBus.Object ogsmd_cb;
    dynamic DBus.Object ogsmd_monitor;

    Logger logger;

    construct
    {
        logger = new Logger();

        try
        {
            debug( "monitor object created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );

            framework = conn.get_object( FSO_FSO_BUS_NAME, FSO_FSO_OBJ_PATH, FSO_FSO_IFACE );
            debug( "attached to frameworkd %s. Gathering objects...", framework.GetVersion() );

            /*
            usage = conn.get_object( FSO_USAGE_BUS_NAME, FSO_USAGE_OBJ_PATH, FSO_USAGE_IFACE );
            usage.ResourceAvailable += logger.usage_resource_available;
            */

            testing = conn.get_object( FSO_TEST_BUS_NAME, FSO_TEST_OBJ_PATH, FSO_TEST_IFACE );
            testing.Test += logger.testing_test;

            //ogsmd_device = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_DEV_IFACE );
            //ogsmd_device.ThisVersionNotThere();

            ogsmd_sim = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_SIM_IFACE );
            ogsmd_sim.Ping();

            ogsmd_network = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_NET_IFACE );
            ogsmd_network.Ping();

            ogsmd_call = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CALL_IFACE );
            ogsmd_call.Ping();

            ogsmd_pdp = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_PDP_IFACE );
            ogsmd_pdp.Ping();

            ogsmd_cb = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_CB_IFACE );
            ogsmd_cb.Ping();

            ogsmd_monitor = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_MON_IFACE );
            ogsmd_monitor.Ping();

            debug( "... done." );

        } catch (DBus.Error e) {
            error( e.message );
        }
    }

}
