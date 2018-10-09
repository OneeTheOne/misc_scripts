import requests
import json
from requests.auth import HTTPBasicAuth


url = 'https://ncrsmb.testrail.net/index.php?'
user = 'jiri.kralik@ncr.com'
api_key = 'bfttK/zQC.CEhuQ9rQzu-Q4qDRz0dPeu56bFfSSEU'

project_id = '16'
milestone_id = '76'

get_url = url +'/api/v2/get_runs/' + project_id + '&milestone_id=' + milestone_id

s = requests.session()
s.auth = (user, api_key)
s.headers.update({'Content-Type': 'application/json'})

r = s.get(get_url)
json_array = r.json()
print (json_array)


run_ids = []
for a in json_array:
    if not a["is_completed"]:
        run_ids.append(a["id"])


if not run_ids:
    print('No open runs found.. Terminatng')
else:
    for run_id in run_ids:
        complete_url = url + '/api/v2/delete_run/' + str(run_id)
        r = s.post(complete_url)
        print(r)