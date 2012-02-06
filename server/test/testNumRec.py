from roundwared import server
from roundwared import settings
settings.initialize_config('/etc/roundware/oceanvoices')

req = {
    'categoryid' : "7",
    'genderid' : "2",
    'ageid' : "17",
    'subcategoryid' : "8",
    'questionid' : "23\t17\t20\t19\t21\t16",
    'usertypeid' : "1\t15\t2\t5\t13\t14\t16\t4\t3\t6",
}

print server.number_of_recordings(req)
