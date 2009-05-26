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
using Posix;

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
        string output = null;
        string errput = null;

        int status = 0;
        if( ! list_contains( stopped_daemons, name ) )
        {
            try
            {
                var con = DBus.Bus.get( BusType.SYSTEM );
                dynamic DBus.Object dbus = con.get_object( "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus" );
                uint pid = dbus.GetConnectionUnixProcessID( name );
                string[] cmd_split = get_cmd_for_pid( pid );
                Posix.kill( (Posix.pid_t)pid, 9 );
                string cmd = string.joinv( " ", cmd_split );

                stopped_daemons.append( name );
                Timeout.add_seconds( restart_timeout, ( GLib.SourceFunc )remove_daemon );
                Process.spawn_command_line_sync( cmd, out output, out errput, out status );
            }
            catch (GLib.SpawnError e)
            {
                debug( "Spawn failed: %s",e.message );
                debug( "stdout: %s", output );
                debug( "stderr: %s", errput );
            }
            catch ( DBus.Error ex )
            {
                debug( "DBus error for %s: %s", name, ex.message );
            }
        }
        else
             debug( "%s already restarted", name );
    }

    public static string[] get_cmd_for_pid( uint pid )
    {
        string[] lines = new string[0];
        int fd = 0;
        if( ( fd = Posix.open(  "/proc/%u/cmdline".printf( pid ) , Posix.O_RDONLY) ) > 0)
        {
            char[] buf = new char[4096];
            size_t len = 0;
            if( ( len = Posix.read( fd, buf, 4096 ) ) > 0 )
            {
                char[] tmp = new char[1024];
                int tmppos = 0;
                for( int bufpos = 0; bufpos < len; bufpos ++ )
                {
                    tmp[tmppos] = buf[bufpos];
                    if( tmp[tmppos] == '\0' )
                    {
                        lines += Posix.strdup( ( string )tmp );
                        tmppos = 0;
                    }
                    else
                         tmppos ++;
                }
                lines += null;
            }
            else
            {
                debug( "Read for pid %u failed: %s", pid, Posix.strerror( Posix.errno ) );
                lines = null;
            }
        }
        else
        {
            debug( "open for pid %u failed: %s", pid, Posix.strerror( Posix.errno ) );
            lines = null;
        }
        return lines;
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
