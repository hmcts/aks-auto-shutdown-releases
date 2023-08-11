#!/usr/bin/env python3
import requests
import json
from datetime import datetime, date, timedelta
from dateutil.parser import parse
import numpy as np
import os

vm_sku = os.getenv("AKS_NODE_SKU")
vm_num = os.getenv("AKS_NODE_COUNT")
vm_num_int = int(vm_num)
start_date = os.getenv("START_DATE")
end_date = os.getenv("END_DATE")
print("=== Printing Vars ===")
print(vm_sku)
print(vm_num)
print(vm_num_int)
print(start_date)
print(end_date)
print("===============")

api_url = "https://prices.azure.com/api/retail/prices?currencyCode='GBP&api-version=2021-10-01-preview"
query = "armRegionName eq 'uksouth' and skuName eq '" + vm_sku + "' and priceType eq 'Consumption' and productName eq 'Virtual Machines Ddsv5 Series'"
response = requests.get(api_url, params={'$filter': query})
json_data = json.loads(response.text)

print("******")
print(query)
print("******")

print(json_data)

for item in json_data['Items']:
    vm_hour_rate = item['retailPrice']

start = parse(start_date, dayfirst=True).date()
start_date = start.strftime("%d-%m-%Y")

end = parse(end_date, dayfirst=True).date()
end_date = end.strftime("%d-%m-%Y")

business_days = np.busday_count(start, (end + timedelta(days=1)))

diff = (end - start).days
total_days = (diff +1)
weekend_days = (total_days - business_days)

def calculate_cost(env_rate, vm_num_int, skip_bus_days, skip_weekend_days):
    bus_hours = (8 * skip_bus_days)
    weekend_hours = (24 * skip_weekend_days)
    total_hours = (bus_hours + weekend_hours)
    vm_cost = (env_rate * total_hours)*vm_num_int
    total_cost = ((vm_cost // 100) * 25) + vm_cost
    print("£" + str(total_cost))

calculate_cost(vm_hour_rate, vm_num_int, business_days, weekend_days)