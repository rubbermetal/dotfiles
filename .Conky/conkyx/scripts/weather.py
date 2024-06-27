#!/usr/bin/python
'''
This script fetches weather data from the AccuWeather RSS feed based on the
location code provided as a command-line argument.
'''
import argparse
import requests
import xmltodict

# 0 for Fahrenheit - 1 for Celsius
METRIC = 0

def get_weather(location_code):
    # URL to fetch weather data
    url = f'http://rss.accuweather.com/rss/liveweather_rss.asp?metric={METRIC}&locCode={location_code}'
    # Make a GET request to the URL
    response = requests.get(url)
    # Get the XML data from the response
    xml_data = response.text
    
    # Print the XML data for debugging
    print("Received XML data:")
    print(xml_data)

    try:
        # Parse the XML data
        parsed_data = xmltodict.parse(xml_data)
        # Get the list of items from the parsed data
        items = parsed_data["rss"]["channel"]["item"]
        # Ensure items is a list
        if not isinstance(items, list):
            items = [items]
        # Iterate through the items
        for item in items:
            weather = item["title"]
            # Check if the title contains "Currently:"
            if "Currently:" in weather:
                # Remove "Currently:" from the title
                weather = weather.replace("Currently:", "")
                print(weather)
                # Exit the loop
                break
        else:
            # If the loop completes without breaking
            print("Error: Could not fetch weather data.")
    except Exception as e:
        print(f"Error parsing XML: {e}")

if __name__ == '__main__':
    # Create an argument parser
    parser = argparse.ArgumentParser(description='AccuWeather (r) RSS weather tool for conky')
    # Add a required argument for location code
    parser.add_argument('locationcode', help='location code')
    # Parse the arguments
    args = parser.parse_args()
    # Get the location code from the arguments
    location_code = args.locationcode
    # Call the get_weather function with the location code
    get_weather(location_code)

