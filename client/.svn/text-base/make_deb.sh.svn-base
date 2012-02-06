#!/bin/sh
python2.5 setup.py bdist_dumb
cd dist
echo "Cleaning any previous debs"
rm -rf RoundClient-1.0.linux-armv5tel
rm -f RoundClient-1.0.linux-armv5tel.deb
mkdir RoundClient-1.0.linux-armv5tel
cp -a DEBIAN RoundClient-1.0.linux-armv5tel/
chmod 775 RoundClient-1.0.linux-armv5tel/DEBIAN/postinst
cd RoundClient-1.0.linux-armv5tel
tar xfz ../RoundClient-1.0.linux-*.tar.gz
find ./ -name "*.pyc" | xargs -n 1 rm
cd ..
dpkg-deb --build RoundClient-1.0.linux-armv5tel
