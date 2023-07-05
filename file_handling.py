
import json
import os
from datetime import datetime
from datetime import date
from dateutil.parser import parse

listObj = []
filepath = 'issues_list.json'
new_data = json.loads(os.environ.get('NEW_DATA', '{}'))
issue_number = os.environ.get('ISSUE_NUMBER')
github_repository = os.environ.get('GITHUB_REPO')
print(github_repository)
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
  print(len(listObj))
  listObjwrite = []
  for x in range(len(listObj)):
    print("================")
    print(x)
    d = listObj[x]
    print(d)
    print(type(d))
    end_date = parse(d['Skip shutdown end date'], dayfirst = True).date()
    print(end_date)
    print(type(end_date))
    if today <= end_date:
      end_date = end_date.strftime('%d-%m-%Y')
      print(end_date)
      listObjwrite.append(d)
    else:
      exit()
    print(listObjwrite) 
  if new_data:
    new_data['issue_link'] = "https://github.com/" + github_repository + "/issues/" + issue_number
    if new_data['Skip shutdown end date'] == "_No response_":
      new_data['Skip shutdown end date'] = today.strftime('%d-%m-%Y')
    listObjwrite.append(new_data)
    elif new_data['Skip shutdown end date'] != "_No response_":
      print(d['Skip shutdown end date'])
      new_data = parse(d['Skip shutdown end date'], dayfirst = True).date().strftime('%d-%m-%Y')
      print(d['Skip shutdown end date'])
    listObjwrite.append(new_data)
  print("before write")  
  print(listObjwrite)
  with open(filepath, "w") as json_file:
    json.dump(listObjwrite, json_file, indent=4)
