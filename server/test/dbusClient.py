import dbus
import sys

ifacename = "org.roundware.StreamScript"
def skip_ahead (name):
        bus = dbus.SystemBus()
        remote_object = bus.get_object(ifacename, "/org/roundware/StreamScript/"+name)
        iface = dbus.Interface(remote_object, ifacename)
        return remote_object.skip_ahead(dbus_interface = iface)

print "Running client named "+sys.argv[1]
print skip_ahead(sys.argv[1])


