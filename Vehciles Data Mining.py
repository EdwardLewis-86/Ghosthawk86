import requests
import pandas as pd
import os
from bs4 import BeautifulSoup
import re

# Output directory
output_dir = r"C:\Users\Lewis\OneDrive - Motus Corporation\Documents\3. RStudio_Python Outputs"
os.makedirs(output_dir, exist_ok=True)

# Output file name
output_file = os.path.join(output_dir, "Vehicle_Make_Model_Type.xlsx")

# --- Function to get vehicle makes from NHTSA API ---
def get_all_vehicle_makes():
    url = "https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes?format=json"
    response = requests.get(url)
    data = response.json()
    makes = data["Results"]
    return makes

# --- Function to get models for a given make ---
def get_models_for_make(make_name):
    url = f"https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/{make_name}?format=json"
    response = requests.get(url)
    data = response.json()
    models = data["Results"]
    return models

# --- Function to scrape Wikipedia list of automobile manufacturers ---
def scrape_wikipedia_automobiles():
    url = "https://en.wikipedia.org/wiki/List_of_automobile_manufacturers"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, "html.parser")

    manufacturers = []

    # Look for links under each continent section
    for li in soup.select("div.div-col li a"):
        make = li.get_text(strip=True)
        if make and not re.match(r"\[.*\]", make):  # Exclude weird refs
            manufacturers.append({
                "Vehicle Make": make,
                "Vehicle Model": "Unknown",
                "Type of Vehicle": "Passenger"
            })

    return manufacturers

# --- Function to scrape Wikipedia list of motorcycle manufacturers ---
def scrape_wikipedia_motorcycles():
    url = "https://en.wikipedia.org/wiki/List_of_motorcycle_manufacturers"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, "html.parser")

    manufacturers = []

    # Look for list items
    for li in soup.select("div.div-col li"):
        make = li.get_text(strip=True)
        if make and not re.match(r"\[.*\]", make):
            manufacturers.append({
                "Vehicle Make": make,
                "Vehicle Model": "Unknown",
                "Type of Vehicle": "Motorbike"
            })

    return manufacturers

# --- Main script ---
all_data = []

print("Fetching all vehicle makes from NHTSA...")
makes_list = get_all_vehicle_makes()
print(f"Found {len(makes_list)} makes.")

# Loop through each make
for i, make in enumerate(makes_list):
    make_id = make["Make_ID"]
    make_name = make["Make_Name"]

    try:
        models = get_models_for_make(make_name)

        for model in models:
            model_name = model["Model_Name"]
            vehicle_type = "Unknown"

            # Inference rules
            if "motor" in model_name.lower() or "bike" in model_name.lower():
                vehicle_type = "Motorbike"
            elif "truck" in model_name.lower() or "van" in model_name.lower():
                vehicle_type = "Commercial"
            else:
                vehicle_type = "Passenger"

            all_data.append({
                "Vehicle Make": make_name,
                "Vehicle Model": model_name,
                "Type of Vehicle": vehicle_type
            })

        if (i + 1) % 50 == 0:
            print(f"Processed {i + 1} / {len(makes_list)} makes...")

    except Exception as e:
        print(f"Error fetching models for make {make_name}: {e}")

# --- Wikipedia scrape ---
print("Scraping Wikipedia automobile manufacturers...")
wiki_autos = scrape_wikipedia_automobiles()
print(f"Found {len(wiki_autos)} Wikipedia automobile makes.")

print("Scraping Wikipedia motorcycle manufacturers...")
wiki_bikes = scrape_wikipedia_motorcycles()
print(f"Found {len(wiki_bikes)} Wikipedia motorcycle makes.")

# --- Merge all data ---
combined_data = pd.DataFrame(all_data + wiki_autos + wiki_bikes)
print(f"Combined total records: {len(combined_data)}")

# --- Clean and deduplicate ---
combined_data["Vehicle Make"] = combined_data["Vehicle Make"].str.strip()
combined_data["Vehicle Model"] = combined_data["Vehicle Model"].str.strip()

# Remove exact duplicates
combined_data = combined_data.drop_duplicates()

# Sort
combined_data = combined_data.sort_values(by=["Vehicle Make", "Vehicle Model"]).reset_index(drop=True)

# --- Save to Excel ---
combined_data.to_excel(output_file, index=False)
print(f"Excel saved to: {output_file}")

print("All done!")
