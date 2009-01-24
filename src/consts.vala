/*
 * const.vala
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
namespace CONST
{
    public const string FSO_FSO_BUS_NAME   = "org.freesmartphone.frameworkd";
    public const string FSO_FSO_OBJ_PATH   = "/org/freesmartphone/Framework";
    public const string FSO_FSO_IFACE      = "org.freesmartphone.Framework";

    public const string FSO_TEST_BUS_NAME   = "org.freesmartphone.testing";
    public const string FSO_TEST_OBJ_PATH   = "/org/freesmartphone/Testing";
    public const string FSO_TEST_IFACE      = "org.freesmartphone.Testing";

    public const string FSO_USAGE_BUS_NAME = "org.freesmartphone.ousaged";
    public const string FSO_USAGE_OBJ_PATH = "/org/freesmartphone/Usage";
    public const string FSO_USAGE_IFACE    = "org.freesmartphone.Usage";

    public const string FSO_DEV_BUS_NAME = "org.freesmartphone.odeviced";
    public const string FSO_DEV_POWER_OBJ_PATH = "/org/freesmartphone/Device/PowerSupply/battery";
    public const string FSO_DEV_POWER_IFACE    = "org.freesmartphone.Device.PowerSupply";

    public const string FSO_GSM_BUS_NAME   = "org.freesmartphone.ogsmd";
    public const string FSO_GSM_OBJ_PATH   = "/org/freesmartphone/GSM/Device";
    public const string FSO_GSM_DEV_IFACE  = "org.freesmartphone.GSM.Device";
    public const string FSO_GSM_SIM_IFACE  = "org.freesmartphone.GSM.SIM";
    public const string FSO_GSM_NET_IFACE  = "org.freesmartphone.GSM.Network";
    public const string FSO_GSM_CALL_IFACE = "org.freesmartphone.GSM.Call";
    public const string FSO_GSM_PDP_IFACE  = "org.freesmartphone.GSM.Pdp";
    public const string FSO_GSM_CB_IFACE   = "org.freesmartphone.GSM.CellBroadcast";
    public const string FSO_GSM_MON_IFACE  = "org.freesmartphone.GSM.Monitor";
    public const string FSO_GSM_SMS_IFACE   = "org.freesmartphone.GSM.SMS";
    public const string FSO_GSM_PHONE_OBJ_PATH   = "/org/freesmartphone/GSM/Server";
    public const string FSO_GSM_HZ_IFACE   = "org.freesmartphone.GSM.HZ";

    public const string FDO_GYPSY_ACCURACY_IFACE = "org.freedesktop.Gypsy.Accuracy";
    public const string FDO_GYPSY_COURSE_IFACE = "org.freedesktop.Gypsy.Course";
    public const string FDO_GYPSY_DEVICE_IFACE = "org.freedesktop.Gypsy.Device";
    public const string FDO_GYPSY_POSITION_IFACE = "org.freedesktop.Gypsy.Position";
    public const string FDO_GYPSY_TIME_IFACE = "org.freedesktop.Gypsy.Time";
}
