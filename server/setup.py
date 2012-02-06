import glob
import os
import stat
from distutils.core import setup
from distutils.extension import Extension

setup(
	name		= "Roundware Server",
	version		= "1.0",
	description	= 'Roundware Server',
	author		= 'Mike MacHenry',
	author_email	= 'mike.machenry@gmail.com',
	url		= 'http://roundware.sourceforge.net',
	license		= 'GPL',
	scripts		= glob.glob('bin/*'),
	packages	= ["roundwared"],
	data_files = [
		('/usr/lib/cgi-bin', glob.glob('cgi-bin/*.py')),
		('/var/www/roundware', glob.glob('www/*py')),
		('/etc/dbus-1/system.d', ['data_files/org.roundware.StreamScript.conf']),
	],
)

# chmod all cgi-bin files to executable.
for file in glob.glob('cgi-bin/*.py'):
	os.chmod(
		os.path.join('/usr/lib/cgi-bin', os.path.basename(file)),
		stat.S_IRWXU | stat.S_IROTH | stat.S_IXOTH | stat.S_IXGRP | stat.S_IRGRP)

