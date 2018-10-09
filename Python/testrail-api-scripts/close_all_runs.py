import requests
import json
from requests.auth import HTTPBasicAuth


url = 'https://ncrsmb.testrail.net/index.php?'
user = 'jiri.kralik@ncr.com'
api_key = 'bfttK/zQC.CEhuQ9rQzu-Q4qDRz0dPeu56bFfSSEU'

project_id = '16'
milestone_id = '74'

get_url = url +'/api/v2/get_runs/' + project_id + '&milestone_id=' + milestone_id

s = requests.session()
s.auth = (user, api_key)
s.headers.update({'Content-Type': 'application/json'})

r = s.get(get_url)
json_array = r.json()


run_ids = []
for a in json_array:
    if not a["is_completed"]:
        run_ids.append(a["id"])


if not run_ids:
    print('No open runs found.. Terminatng')
else:
    for run_id in run_ids:
        close_run_url = url + '/api/v2/close_run/' + str(run_id)
        r = (s.post(close_run_url)).json()
        print(r)
