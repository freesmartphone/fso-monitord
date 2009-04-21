/*
* File Name: monitor.vala
* Creation Date:
* Last Modified: 
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
using DBus;


namespace FSO
{
    public interface IMonitor
    {
        public abstract void run();
        public abstract void stop();
    }
    public class System:GLib.Object, IMonitor
    {
        protected List<Subsystem> subsystems = null;
        protected Logger logger = null;
        protected DBus.Connection con = null;
        protected dynamic DBus.Object dbus;
        protected string busname = null;
        public System( FSO.Logger l, DBus.Connection c)
        { 
            this.con = c;
            this.logger = l;
        }
        construct
        { 
            this.subsystems = new List<Subsystem>( );
        }
        public void name_owner_changed( dynamic DBus.Object obj, string name, string new_owner, string old_owner)
        {
            if( name == this.busname )
            {
                stop();
                run();
            }
        }
        public virtual void run()
        {
            this.dbus = this.con.get_object( "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus" );
            this.dbus.NameOwnerChanged += this.name_owner_changed;

            foreach( Subsystem s in this.subsystems )
            {
                s.run();
            }
        }
        public virtual void stop()
        {
            foreach( Subsystem s in this.subsystems )
            {
                s.stop();
            }
        }
    }
    public class Subsystem: GLib.Object, IMonitor
    {
        protected Logger logger = null;
        protected DBus.Connection con = null;
        protected dynamic DBus.Object object =null;
        protected string _IFACE = null;
        protected string _BUS_NAME = null;
        protected string _OBJ_PATH = null;
        protected string name = null;
        //currently everything is provided by frameworkd
        protected string daemon = "frameworkd";


        public Subsystem( FSO.Logger l, DBus.Connection c, string name = "" )
        {
            this.con = c;
            this.logger = l;
            this.name = name;
        }
        
        public virtual void run()
        {
            debug( "Gathering Object: BUS:%s OBJ_PATH:%s IFACE:%s", this._BUS_NAME, this._OBJ_PATH, this._IFACE );
            this.object = this.con.get_object( this._BUS_NAME, this._OBJ_PATH, this._IFACE );
            try
            {
                this.object.Ping();
            }
            catch( GLib.Error e )
            {
                debug("Ping failed. BUSNAME: %s OBJPATH: %s IFACE: %s: %s", this._BUS_NAME, this._OBJ_PATH, this._IFACE, e.message );
            }
            var rand = new Rand();
            Timeout.add_seconds( rand.int_range( 10, FSO.timeout), this.first_ping );
        }
        public bool first_ping( )
        {
            ping();
            Timeout.add_seconds( FSO.timeout, this.ping );
            
            //Don't call me again
            return false;
        }
        public bool ping( )
        {
            try
            {
                debug( "Pinging %s ", this.object.get_path( ) );
                this.object.Ping();
            }
            catch( GLib.Error e )
            {
                debug("Ping failed. BUSNAME: %s OBJPATH: %s IFACE: %s: %s", this._BUS_NAME, this._OBJ_PATH, this._IFACE, e.message );
                FSO.restart( this.daemon );
            }
            //Call me again
            return true;
        }
        public virtual void stop()
        {
            this.object= null;
        }
    }
    public class Monitor: GLib.Object, IMonitor
    { 
        private DBus.Connection conn = null;
        private Logger logger = null;
        private List<System> systems = null;
        public Monitor( Logger l, DBus.Connection c)
        {
            this.logger = l;
            this.conn = c;
            this.logger.logINFO("-------------Monitor restarted------------");
            this.systems.prepend(new FSO.Device(this.logger, this.conn));
            this.systems.prepend(new FSO.GSM(this.logger, this.conn));
            this.systems.prepend(new FSO.Phone(this.logger, this.conn));
            this.systems.prepend(new FSO.Preferences(this.logger, this.conn));
            this.systems.prepend(new FSO.Usage(this.logger, this.conn));
            this.systems.prepend(new FSO.Framework(this.logger, this.conn));
        }
        construct
        {
            this.systems = new List<System>();
        }
        public virtual void run()
        {
            foreach( System s in this.systems )
            {
                debug( "Starting: %s", s.get_type().name() );
                s.run();
            }
        }
        public virtual void stop()
        {
            foreach( System s in this.systems )
            {
                s.stop();
            }
        }
        public static int main(string[] args)
        {
            var logger = new FSO.Logger();
            var loop = new MainLoop(null, false);
            try
            {
                var con = DBus.Bus.get( DBus.BusType.SYSTEM );
                var monitor = new FSO.Monitor( logger, con );
                monitor.run(  );
                loop.run();
            } catch (GLib.Error e) {
                stderr.printf ("Oops: %s\n", e.message);
                return 1;
            }
            return 0;
        }

    }
} 
