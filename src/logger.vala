/*
 * logger.vala
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
public class Logger : Object
{

    /* public */

    public Logger(string logfile = "/tmp/fso-monitor.log" )
    {
    this.log_path = logfile;
        this.stream = FileStream.open( this.log_path, "a+" );
    if( this.stream == null)
    {
        error("Can't open %s", this.log_path);
    }

        log("INFO", 0, "logger restarted" );
    }


    public void log (string? log_domain, LogLevelFlags flags,string message) 
    {
        var tv = TimeVal();
        string time = tv.to_iso8601();
        stream.printf("%s %s %s\n", time, log_domain, message);
        stream.flush();
    }
    /* private */
    private FileStream stream;
    private string log_path;

}

