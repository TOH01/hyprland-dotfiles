import json,os,configparser,glob
try:
    import gi
    gi.require_version('Gtk','3.0')
    from gi.repository import Gtk
    theme=Gtk.IconTheme.get_default()
except:
    theme=None
R={}
for f in glob.glob('/usr/share/applications/*.desktop')+glob.glob(os.path.expanduser('~/.local/share/applications/*.desktop'))+glob.glob('/var/lib/flatpak/exports/share/applications/*.desktop')+glob.glob(os.path.expanduser('~/.local/share/flatpak/exports/share/applications/*.desktop')):
    cp=configparser.ConfigParser(interpolation=None)
    try: cp.read(f)
    except: continue
    if not cp.has_section('Desktop Entry'): continue
    ic=cp.get('Desktop Entry','Icon',fallback='')
    wm=cp.get('Desktop Entry','StartupWMClass',fallback='')
    bn=os.path.splitext(os.path.basename(f))[0]
    name=cp.get('Desktop Entry','Name',fallback='')
    if not ic: continue
    p=''
    if ic.startswith('/'):
        p=ic if os.path.exists(ic) else ''
    elif theme:
        info=theme.lookup_icon(ic,48,0)
        p=info.get_filename() if info else ''
    if p:
        for k in [wm,wm.lower(),bn,bn.lower(),ic,ic.lower(),name,name.lower()]:
            if k and k not in R: R[k]=p
print(json.dumps(R))