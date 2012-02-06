#!/usr/bin/env python

import gobject
import dbus
import dbus.service
import dbus.glib
import sys

iface = 'org.roundware.StreamScript'
class StreamDBusListener (dbus.service.Object):
        def __init__(self, name):
		bus_name = dbus.service.BusName(iface, bus = dbus.SystemBus(), replace_existing=True)
		print bus_name
		myname = dbus.SystemBus().request_name(iface)
		print myname
                dbus.service.Object.__init__(self, bus_name, "/org/roundware/StreamScript/"+name)

        @dbus.service.method(dbus_interface=iface, in_signature='', out_signature='b')
        def skip_ahead(self):
                return True

print "Running server named " + sys.argv[1]
object = StreamDBusListener(sys.argv[1])
gobject.MainLoop().run()

