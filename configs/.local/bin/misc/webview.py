#!/usr/bin/env python3
import gi, sys
gi.require_version('Gtk', '4.0')
gi.require_version('WebKit', '6.0')
from gi.repository import Gtk, WebKit

url = sys.argv[1]

app = Gtk.Application()

def on_activate(app):
    win = Gtk.ApplicationWindow(application=app)
    win.set_decorated(False)
    session = WebKit.NetworkSession.get_default()
    session.set_tls_errors_policy(WebKit.TLSErrorsPolicy.IGNORE)
    web = WebKit.WebView(network_session=session)
    web.load_uri(url)
    web.set_vexpand(True)
    win.set_child(web)
    win.present()

app.connect("activate", on_activate)
app.run()