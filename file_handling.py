
import json
import os
from datetime import datetime
from datetime import date
from dateutil.parser import parse

listObj = []
filepath = 'issues_list.json'
new_data = json.loads(os.environ.get('NEW_DATA', '{}'))
new_data["skip_start_date"]=new_data.pop("Skip shutdown start date")
new_data["skip_end_date"]=new_data.pop("Skip shutdown end date")
new_data["environment"]=new_data.pop("Environment")
new_data["business_area"]=new_data.pop("Business area")
print("==================")
issue_number = os.environ.get('ISSUE_NUMBER')
github_repository = os.environ.get('GITHUB_REPO')
print("todays date")
today = date.today()
print(today)

try:
  with open(filepath, "r") as json_file:
    listObj = json.load(json_file)
except FileNotFoundError:
  with open(filepath, "w") as json_file:
    listObj.append(new_data)
    json.dump(listObj, json_file, indent=4)
else:
  listObjwrite = []
  for x in range(len(listObj)):
    print("================")
    d = listObj[x]
    end_date = parse(d['skip_end_date'], dayfirst = True).date()
    if today <= end_date:
      end_date = end_date.strftime('%d-%m-%Y')
      print(end_date)
      listObjwrite.append(d)
    else:
      print("Error: Cannot have an end date in the past")
      exit()
    print(listObjwrite) 
  if new_data:
    new_data['issue_link'] = "https://github.com/" + github_repository + "/issues/" + issue_number
    if new_data['skip_end_date'] == "_No response_":
      new_data['skip_end_date'] = today.strftime('%d-%m-%Y')

    elif new_data['skip_end_date'] != "_No response_":
      end_date = parse(new_data['skip_end_date'], dayfirst = True).date().strftime('%d-%m-%Y')
      new_data['skip_end_date'] = end_date
    listObjwrite.append(new_data)
  print("before write")  
  print(listObjwrite)
  with open(filepath, "w") as json_file:
    json.dump(listObjwrite, json_file, indent=4)
