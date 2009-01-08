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
    private string[] _xmldata;

    public List<string> interfaces;
    public List<string> nodes;

    public Logger( string xmldata )
    {
        debug( "introspection object created" );
        _xmldata = xmldata.split( "\n" );

        foreach ( string line in _xmldata )
        {
            //debug( "dealing with line '%s'", line );
            int res = 0;
            string name;
            res = line.scanf( "  <node name=\"%a[a-zA-Z0-9_]\"/>", out name );
            if ( res == 1 )
            {
                nodes.append( name );
                message( "object has node '%s'", name );
            }
            res = line.scanf( "  <interface name=\"%a[a-zA-Z0-9_.]\">", out name );
            if ( res == 1 )
            {
                message( "object supports interface '%s'", name );
                interfaces.append( name );
            }
        }
    }
}

//===========================================================================
public class Monitor : Object
{
    DBus.Connection conn;
    dynamic DBus.Object ogsmd_device;

    construct
    {
        try
        {
            debug( "monitor object created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            ogsmd_device = conn.get_object( FSO_GSM_BUS_NAME, FSO_GSM_OBJ_PATH, FSO_GSM_DEV_IFACE );
        } catch (DBus.Error e) {
            error( e.message );
        }
    }
}
