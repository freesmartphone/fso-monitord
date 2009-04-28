/*
 * File Name: fso.vala
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
using DBus;

namespace FSO
{
    //ping every 5 minutes
    public static int timeout = 5*60;
    public static int restart_timeout = 2*60;
    public static SList<string> stopped_daemons;
    public static bool remove_daemon( GLib.Object? dummy )
    {
        //no pop_front
        stopped_daemons.remove( stopped_daemons.data );
        return false;
    }
    public static void restart( string name )
    {
        if( stopped_daemons == null )
        {
            stopped_daemons = new SList<string>();
        }
        //TODO: get this from env or somewhere else
        //Environment.get_system_config_dirs only returns /etc/xdg
        string path = Path.build_filename( "/etc","init.d", name );
        string command = "%s %s".printf( path, " restart");
        string output = null;
        string errput = null;

        int status = 0;
        if( ! list_contains( stopped_daemons, name ) )
        {
            try
            {
                stopped_daemons.append( name );
                Timeout.add_seconds( restart_timeout, ( GLib.SourceFunc )remove_daemon );
                Process.spawn_command_line_sync( command, out output, out errput, out status );
            }
            catch (GLib.SpawnError e)
            {
                debug( "Spawn failed: %s",e.message );
                debug( "stdout: %s", output );
                debug( "stderr: %s", errput );
            }
        }
        else
             debug( "%s already restarted", name );
    }

    public static bool list_contains( SList<string>? the_list, string needle )
    {
        if( the_list == null )
             return false;
        foreach( string s in the_list )
        {
            if( s == needle )
                 return true;
        }
        return false;
    }
    public class Framework: System
    {
        public const string BUS_NAME   = "org.freesmartphone.frameworkd";
        public const string OBJ_PATH   = "/org/freesmartphone/Framework";
        public string IFACE      = "org.freesmartphone.Framework";

        private dynamic DBus.Object object;
        
        public Framework( FSO.Logger l, DBus.Connection c )
        {
            base(l,c);
            this.busname = BUS_NAME;
        }

        public override void run() throws GLib.Error
        {
            base.run();
            try
            {
                this.object = this.con.get_object( BUS_NAME, OBJ_PATH, IFACE );
                debug( "Attached to frameworkd %s. Gathering objects...", this.object.GetVersion() );
            }
            catch (GLib.Error e)
            {
                debug( "Gathering frameword: %s", e.message );
            }
        }
        public override void stop()
        {
            base.stop();
        }
    }
}
