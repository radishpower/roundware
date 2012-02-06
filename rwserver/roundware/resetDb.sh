echo "drop database round_django;" | mysql -uround -pround  
echo "create database round_django;" | mysql -uround -pround
python manage.py syncdb
