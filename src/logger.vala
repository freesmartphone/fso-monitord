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
    else if( value.holds( typeof( uint ) ) )
    {
        val = value.get_uint().to_string();
    }
    else if( value.holds( typeof( double ) ) )
    {
        val = value.get_double().to_string();
    }
    else if( value.holds( typeof( float ) ) )
    {
        val = value.get_float().to_string();
    }
    else if( value.holds( typeof( char ) ) )
    {
        val = value.get_char().to_string();
    }
    else
    {
        val = "unknown type: " + value.type_name();
    }

    return val;
}


//===========================================================================
public class Logger : Object
{
    /* private */
    private FileStream stream;
    private string log_path;
    private string buf;
    private string cur_domain;

    private void log_hash_table( string k, Value v)
    {
        stream.printf("\t\t%s:%s\n", k, value_to_string(v) );
    }


    /* public */

    public Logger(string logfile = "/tmp/fso-monitor.log" )
    {
        this.log_path = logfile;
            this.stream = FileStream.open( this.log_path, "a+" );
        if( this.stream == null)
        {
            error("Can't open %s", this.log_path);
        }

    }
	public void logDATA( string message )
	{
		this.log("DATA").message(message);
	}
	public void logINFO( string message)
	{
		this.log("INFO").message(message);
	}


    public unowned Logger log(string domain)
    {
        var tv = TimeVal();
        string time = tv.to_iso8601();
        stream.printf("%s:%s", time, domain);
        return this;
    }
    public unowned Logger message(string msg)
    {
        stream.puts(msg + " ");
        return this;

    }
    public unowned Logger signal(string name)
    {
        stream.puts( "::" + name + " ");
        return this;
    }
    //currently ignored. might be interesting for machine readable code
    public unowned Logger type( Type t)
    {
        return this;
    }
    public unowned Logger name(string name)
    {
        stream.puts( name +  " " );
        return this;
    }
    public unowned Logger value(string name)
    {
        stream.puts( "=" + name + " " );
        return this;
    }
    public unowned Logger from(string name)
    {
        stream.puts( name + " " );
        return this;
    }
    public unowned Logger to(string name)
    {
        stream.puts( "->" + name + " ");
        return this;
    }
    public unowned Logger attributes( HashTable<string,Value?> attr )
    {
        attr.for_each((HFunc) log_hash_table);
        return this;
    }
    public void end()
    {
        stream.flush();
        this.buf = "";
    }

}

