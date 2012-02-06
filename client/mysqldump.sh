# The two sed command fix errors I can't fix with mysqldump
# The first removes backticks. I think --skip-quote-names should
# get rid of these but it leaves them for columns named 'name'
# The second sed command changes the escaping mechanism for
# single quotes inside single-quoted strings from \' to ''

# To use this command, pipe its output to "sqlite3 round.db"

mysqldump \
--skip-extended-insert \
--compatible=no_key_options,no_table_options,no_field_options \
--compact \
--skip-quote-names \
--ignore-table=round.recording \
-uround \
-pround \
round \
| sed s/\`//g \
| sed s/\\\\\'/\'\'/g \
| grep -v "^SET"

