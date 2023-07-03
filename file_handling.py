
import json
import os
from datetime import datetime
from datetime import date

listObj = []
filepath = 'issues_list.json'
new_data = json.loads(os.environ.get('NEW_DATA', '{}'))
read_issue_number = print(os.environ.get('ISSUE_NUMBER'))
print(read_issue_number)
issue_number = {'issue_number': 'number_here'}
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
    listObj.append(issue_number)
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
    if d['Skip shutdown end date'] == "_No response_":
      
      d['Skip shutdown end date'] = today.strftime('%d-%m-%Y')
      print(d)
      listObjwrite.append(d)
      print(listObjwrite)
    else:
      end_date = datetime.strptime(d['Skip shutdown end date'], '%d-%m-%Y').date()
      print( end_date)
      print(type(end_date))
      if today < end_date:
        listObjwrite.append(d)
      print(listObjwrite) 
  if new_data:
    listObjwrite.append(new_data)
  print("before write")  
  print(listObjwrite)
  with open(filepath, "w") as json_file:
    json.dump(listObjwrite, json_file, indent=4)
