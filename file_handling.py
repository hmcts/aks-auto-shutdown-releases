import json
import os
from datetime import datetime
from datetime import date
from dateutil.parser import parse
#Vars
listObj = []
filepath = "issues_list.json"
new_data = json.loads(os.environ.get("NEW_DATA", "{}"))
new_data["skip_start_date"] = new_data.pop("Skip shutdown start date")
new_data["skip_end_date"] = new_data.pop("Skip shutdown end date")
new_data["environment"] = new_data.pop("Environment")
new_data["business_area"] = new_data.pop("Business area")
print("==================")
issue_number = os.environ.get("ISSUE_NUMBER")
github_repository = os.environ.get("GITHUB_REPO")
today = date.today()
env_file = os.getenv("GITHUB_ENV")

#env_vars = open(env_file, "a") as env_file:
 #   env_file.write("PROCESS_SUCCESS=false" + '\n')
#env_vars.close()



if new_data:
    new_data["issue_link"] = (
        "https://github.com/" + github_repository + "/issues/" + issue_number
    )
#Start Date logic
    try:
        new_data["skip_start_date"] = parse(
            new_data["skip_start_date"], dayfirst=True
        ).date()
        if new_data["skip_start_date"] < today:
            raise RuntimeError("Start Date is in the past")
        else:
            date_start_date = new_data["skip_start_date"]
            new_data["skip_start_date"] = new_data["skip_start_date"].strftime("%d-%m-%Y")
    except RuntimeError:
        with open(env_file, "a") as env_file:
            env_file.write("ISSUE_COMMENT=Error")
            print("RuntimeError")
            exit(0)
    except:
        with open(env_file, "a") as env_file:
            env_file.write("ISSUE_COMMENT=Error: Unexpected Date Format")
            print("Unexpected Error")
            exit(0)
#End Date logic
    if new_data["skip_end_date"] == "_No response_":
        if date_start_date > today:
            new_data["skip_end_date"] = new_data["skip_start_date"]
        elif date_start_date == today:
            new_data["skip_end_date"] = today.strftime("%d-%m-%Y")
    elif new_data["skip_end_date"] != "_No response_":
        try:
            new_data["skip_end_date"] = parse(
                new_data["skip_end_date"], dayfirst=True
            ).date()
            if new_data["skip_end_date"] < date_start_date:
                raise RuntimeError("End date cannot be before start date")
            else:
                date_end_date = new_data["skip_end_date"]
                new_data["skip_end_date"] = new_data["skip_end_date"].strftime("%d-%m-%Y")
        except RuntimeError:
            with open(env_file, "a") as env_file:
                env_file.write("ISSUE_COMMENT=Error: End date less than start date")
                exit(0)
        except:
            with open(env_file, "a") as env_file:
                env_file.write("ISSUE_COMMENT=Error: Unexpected Date Format")
                exit(0)
#Write to file
try:
    with open(filepath, "r") as json_file:
        listObj = json.load(json_file)
        listObj.append(new_data)
except FileNotFoundError:
    with open(filepath, "w") as json_file:
        listObj.append(new_data)
finally:
    with open(filepath, "w") as json_file:
        json.dump(listObj, json_file, indent=4)
        with open(env_file, "r") as env_file:
            filedata = file.read()
            filedata = filedata.replace("PROCESS_SUCCESS=false", "PROCESS_SUCCESS=true")
            filedata = filedata.append("ISSUE_COMMENT=Processed Correctly")

        with open(env_file, "W") as env_file:
            env_file.write(filedata)

