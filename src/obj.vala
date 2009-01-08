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
public class Introspection : Object
{
    private string[] _xmldata;

    public List<string> interfaces;
    public List<string> nodes;

    public Introspection( string xmldata )
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
[DBus (name = "org.freesmartphone.DBus")]
public class Server : Object
{
    DBus.Connection conn;
    dynamic DBus.Object dbus;

    construct
    {
        try
        {
            debug( "server object created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            dbus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        } catch (DBus.Error e) {
            error( e.message );
        }
    }

    public string[]? ListBusNames()
    {
        string[] names = null;
        try {
            names = dbus.ListNames();
        } catch (DBus.Error e) {
            error( e.message );
            return names;
        } catch {
            return names;
        }
        return names;
    }

    public string[] ListObjectPaths( string? busname ) throws DBus.Error
    {
        //
        // Check whether the given busname is present on the bus
        //
        var paths = new List<string>();
        var existing_busnames = this.ListBusNames();
        bool found = false;
        foreach ( string name in existing_busnames )
        {
            if ( busname == name )
            {
                found = true;
                break;
            }
        }
        if ( !found )
        {
            message( "requested busname '%s' not found.", busname );
            // FIXME return a dbus error?
            return stringListToArray( paths );
        }
        listObjectPaths( ref paths, busname, "/" );
        return stringListToArray( paths );
    }

    private void listObjectPaths( ref List<string> paths, string busname, string objname ) throws DBus.Error
    {
        debug( "listObjectPaths: %s, %s", busname, objname );
        dynamic DBus.Object obj = conn.get_object( busname, objname, DBUS_INTERFACE_INTROSPECTABLE );
        Introspection data = new Introspection( obj.Introspect() );
        if ( data.interfaces.length() > 1 ) // we don't count the introspection interface that is always present
            paths.append( objname );
        if ( data.nodes.length() > 0 )
            foreach ( string node in data.nodes )
            {
                if ( objname == "/" )
                    listObjectPaths( ref paths, busname, objname+node );
                else
                    listObjectPaths( ref paths, busname, objname+"/"+node );
            }
    }

    public string[] ListObjectsByInterface( string busname, string iface ) throws DBus.Error
    {
        //
        // Check whether the given busname is present on the bus
        //
        var paths = new List<string>();
        var existing_busnames = this.ListBusNames();
        bool found = false;
        foreach ( string name in existing_busnames )
        {
            if ( busname == name )
            {
                found = true;
                break;
            }
        }
        if ( !found )
        {
            message( "requested busname '%s' not found.", busname );
            // FIXME return a dbus error
            return stringListToArray( paths );
        }
        listObjectsByInterface( ref paths, busname, "/", iface );
        return stringListToArray( paths );
    }

    private void listObjectsByInterface( ref List<string> paths, string busname, string objname, string iface ) throws DBus.Error
    {
        debug( "listObjectsByInterface: %s, %s, %s", busname, objname, iface );
        dynamic DBus.Object obj = conn.get_object( busname, objname, DBUS_INTERFACE_INTROSPECTABLE );
        Introspection data = new Introspection( obj.Introspect() );
        if ( data.interfaces.length() > 1 ) // we don't count the introspection interface that is always present
            foreach ( string ifacename in data.interfaces )
            {
                if ( ifacename == iface )
                    paths.append( objname );
            }
        if ( data.nodes.length() > 0 )
            foreach ( string node in data.nodes )
        {
            if ( objname == "/" )
                listObjectsByInterface( ref paths, busname, objname+node, iface );
            else
                listObjectsByInterface( ref paths, busname, objname+"/"+node, iface );
        }
    }
}
