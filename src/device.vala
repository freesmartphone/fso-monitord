/*
 * File Name: device.vala
 * Creation Date: 06-02-2009
 * Last Modified: 08-02-2009
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

namespace FSO
{
    public class Device:System
    {
        [CCode (array_length = false, array_null_terminated = true)]
        private string[] pc_devices;
        [CCode (array_length = false, array_null_terminated = true)]
        private string[] ps_devices;
        private static string BUS_NAME = "org.freesmartphone.odeviced";

        public Device( FSO.Logger l, DBus.Connection c)
        {
            base(l,c);
            this.pc_devices  = { "Bluetooth", "UsbHost", "Wifi", null };
            this.ps_devices = { "ac", "adapter", "apm", "battery", "usb", null };

            foreach( string pc_device in pc_devices )
            {
                this.subsystems.prepend( new PowerControl( this.logger, this.con, pc_device ));
            }
            foreach( string ps_device in ps_devices )
            {
                this.subsystems.prepend(  new PowerSupply( this.logger, this.con, ps_device ) );
            }
            this.subsystems.prepend( new Audio( this.logger, this.con ) );
        }

        //
        //org.freedesktop.Device.PowerControl
        //
        public class PowerControl:Subsystem
        {
            public static  const string IFACE = "org.freesmartphone.Device.PowerControl";
            public static const string BASE_OBJ_PATH = "/org/freesmartphone/Device/PowerControl";
            private bool cur_power;
            public PowerControl( FSO.Logger l, DBus.Connection c, string name)
            {
                base(l,c,name);
                this._OBJ_PATH = "%s/%s".printf(  BASE_OBJ_PATH , name);
                debug( "OBJ_PATH: %s", this._OBJ_PATH );
                this._IFACE = IFACE;
                this._BUS_NAME = FSO.Device.BUS_NAME;
            }
            public override void run()
            {
                base.run();
                this.object.Power += this.power_changed;
                try
                {
                    this.object.GetPower( this.get_power);
                    this.object.Ping();
                }
                catch( GLib.Error e )
                {
                    debug("PowerControl for %s:%s", this.name, e.message );
                }
            }
            public override void stop()
            {
                this.object.Power -= this.power_changed;
                base.stop();
            }
            private void power_changed( dynamic DBus.Object obj, bool on)
            {
                this.logger.log("DEVICE").signal( "USBPower" )
                        .name( "on" ).from( this.cur_power.to_string() ).to( on.to_string())
                        .end();    
                this.cur_power = on;
            }

            private void get_power( dynamic DBus.Object obj, bool on, GLib.Error error)
            {
                if( error != null )
                {
                    debug("Can't get PowerControl for %s %s",this.name, error.message );
                    //Let's say no to have a defined state
                    this.cur_power = false;
                }
                else
                {
                    this.cur_power = on;
                }
            }
        }
        //
        //org.freedesktop.Device.PowerSupply
        //
        public class PowerSupply:Subsystem
        {
            public static const string IFACE = "org.freesmartphone.Device.PowerSupply";
            public static const string BASE_OBJ_PATH = "/org/freesmartphone/Device/PowerSupply";
            private int cur_capacity;
            private string cur_power; 
            public PowerSupply( FSO.Logger l, DBus.Connection c, string name)
            {
                base(l,c,name);
                this._OBJ_PATH = "%s/%s".printf( BASE_OBJ_PATH, name);
                debug( "OBJ_PATH: %s", this._OBJ_PATH );
                this._IFACE = IFACE;
                this._BUS_NAME = FSO.Device.BUS_NAME;
            }
            public override void run()
            {
                debug("Getting PowerSupply Object for %s...", this.name);
                base.run();
                this.object.Capacity += this.capacity_changed;
                this.object.PowerStatus += this.power_status_changed;
                try
                {
                    this.object.GetCapacity( this.get_capacity );
                    this.object.GetPowerStatus( this.get_power_status );
                }
                catch( GLib.Error e )
                {
                    debug("PowerSupply for %s: %s", this.name, e.message );
                }
            }
            public override void stop()
            {
                this.object.PowerStatus -= this.power_status_changed;
                this.object.Capacity -= this.capacity_changed;
                base.stop();
            }
            private void power_status_changed( dynamic DBus.Object obj, string status)
            {
                this.logger.log( "POWERSUPPLY." + this.name ).signal( "PowerStatus").name( "status" ).type(typeof(string) ).from( this.cur_power ).to( status ).end();
                this.cur_power = status;
            }
            private void get_power_status( dynamic DBus.Object obj, string status, 
                        GLib.Error error)
            {
                if( error != null )
                {
                    debug( "Can't get power supply status for %s: %s", this.name, error.message );
                    this.cur_power = "UNKNOWN";
                }
                else
                {
                    this.cur_power = status;
                }
            }
            private void capacity_changed( dynamic DBus.Object obj, int status )
            {
                this.logger.log( "POWERSUPPLY." + this.name ).name( "CapacityChanged" ).type(typeof(int)).from(this.cur_capacity.to_string()).to( status.to_string() ).end();
                this.cur_capacity = status;
            }
            private void get_capacity( dynamic DBus.Object obj, int capacity, GLib.Error error )
            {
                if ( error != null )
                {

                    debug("Can't get capacity for %s: %s",this.name, error.message );
                    this.cur_capacity = -1 ;
                }
                else
                {
                    this.cur_capacity = capacity;
                }
            }
        }
        //
        //org.freedesktop.Device.Input
        //
        public class Input:Subsystem
        {
            public Input( FSO.Logger l, DBus.Connection c, string name = "")
            {
                base(l,c,name);
                this._IFACE = "org.freesmartphone.Device.Input";
                this._OBJ_PATH = "/org/freesmartphone/Device/Input";
                this._BUS_NAME = FSO.Device.BUS_NAME;
            }
            public override void run()
            {
                base.run();
                debug("Getting input Object...");
                this.object.Event += this.input_event;
            }
            public override void stop()
            {
                this.object.Event -= this.input_event;
                base.stop();
            }
            private void input_event( dynamic DBus.Object obj, string name, 
                    string action, int seconds)
            {
                this.logger.log("DEVICE").signal( "Event" )
                    .name("name").type( typeof(string) ).value( name )
                    .name( "action" ).type( typeof(string) ).value( action )
                    .name("seconds").type(typeof(int)).value( seconds.to_string()).end();
            }
        }
        //
        //org.freedesktop.Device.Audio
        //
        public class Audio: Subsystem
        {
            private string cur_scenario;
            public Audio( Logger l, DBus.Connection c, string name = "")
            {
                base(l,c,name);
                this._IFACE = "org.freesmartphone.Device.Audio";
                this._OBJ_PATH = "/org/freesmartphone/Device/Audio";
                this._BUS_NAME = FSO.Device.BUS_NAME;
            }
            public override void run()
            {
                base.run();

                this.object.SoundStatus += this.sound_status_changed;
                this.object.Scenario += this.scenario_changed;
                try
                {
                    this.object.GetScenario ( this.get_scenario );
                }
                catch( GLib.Error e )
                {
                    debug("Can't get Scenario: %s", e.message );
                }
            }
            public override void stop()
            {

                this.object.SoundStatus -= this.sound_status_changed;
                this.object.Scenario -= this.scenario_changed;
                base.stop();
            }
            private void sound_status_changed( dynamic DBus.Object obj, 
                    string id, string status, HashTable<string,Value?> properties )
            {
                this.logger.log("DEVICE").signal("Status")
                    .name("ID").type(typeof(string)).value(id)
                    .name("status").type(typeof(string)).value(status).end();
                //TODO: define properties
            }
            private void scenario_changed( dynamic DBus.Object obj, string scenario)
            {
                this.logger.log("DEVICE").signal( "Scenario changed").name( "scenario").type(typeof(string)).from( this.cur_scenario ).to(  scenario ).end();
                this.cur_scenario = scenario;
            }
            private void get_scenario( dynamic DBus.Object obj, string s, GLib.Error error )
            {
                if( error != null )
                {
                    debug("Can't get scenario: %s" , error.message );
                    this.cur_scenario = "UNKNOWN";
                }
                else
                {
                    this.cur_scenario = s;
                }
            }
        }
    }
}
