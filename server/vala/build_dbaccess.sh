CFG=/usr/bin/mysql_config
/usr/local/bin/valac --ccode --pkg mysql DBAccess.vala DBAccess_test.vala Types.vala && \
sh -c "gcc -o DBAccess_test `pkg-config --cflags gobject-2.0` `pkg-config --cflags glib-2.0` `$CFG --cflags` DBAccess.c DBAccess_test.c Types.c `$CFG --libs` `pkg-config --libs gobject-2.0` `pkg-config --libs gobject-2.0`"

