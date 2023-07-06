import json
import os
from datetime import datetime
from datetime import date
from dateutil.parser import parse

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

if new_data:
    new_data["issue_link"] = (
        "https://github.com/" + github_repository + "/issues/" + issue_number
    )
    try:
        new_data["skip_start_date"] = (
            parse(new_data["skip_start_date"], dayfirst=True)
            .date()
            .strftime("%d-%m-%Y")
        )
        if new_data["skip_start_date"] < today:
          issue_error_comment = "Error, start date cannot be in the past"
          with open(env_file, "a") as env_file:
            env_file.write("ISSUE_COMMENT=" + issue_error_comment)
            exit(0)
    except:
        issue_error_comment = "Error in start date format: " + new_data["skip_start_date"]
        with open(env_file, "a") as env_file:
            env_file.write("ISSUE_COMMENT=" + issue_error_comment)
            exit(0)
    if new_data["skip_end_date"] == "_No response_":
        new_data["skip_end_date"] = today.strftime("%d-%m-%Y")

    elif new_data["skip_end_date"] != "_No response_":
        try:
            new_data["skip_end_date"] = (
                parse(new_data["skip_end_date"], dayfirst=True)
                .date()
                .strftime("%d-%m-%Y")
            )
        except:
            issue_error_comment = "Error in end date format: " + new_data["skip_end_date"]
            with open(env_file, "a") as env_file:
                env_file.write("ISSUE_COMMENT=" + issue_error_comment)
                exit(0)

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
        with open(env_file, "a") as env_file:
            env_file.write("PROCESS_SUCCESS=true" + '\n')
            env_file.write("ISSUE_COMMENT=Processed Correctly")
