CFG=/usr/bin/mysql_config
/usr/local/bin/valac --ccode --pkg mysql TestMySQL.vala && \
sh -c "gcc -o TestMySQL `pkg-config --cflags gobject-2.0` `pkg-config --cflags glib-2.0` `$CFG --cflags` TestMySQL.c `$CFG --libs` `pkg-config --libs gobject-2.0` `pkg-config --libs gobject-2.0`"

