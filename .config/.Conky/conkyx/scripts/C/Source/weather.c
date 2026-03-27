/*
 * AccuWeather RSS Fetcher
 *
 * This C program uses libcurl to fetch weather information from the AccuWeather
 * RSS feed for a specified location code. The fetched data is processed to
 * extract and display the current weather information.
 *
 * Usage:
 *   Compile the program: gcc -o accuweather_fetcher accuweather_fetcher.c -lcurl
 *   Run the program with a location code as a command-line argument:
 *   ./accuweather_fetcher <location_code>
 *
 * Example:
 *   ./accuweather_fetcher 12345
 *
 * Notes:
 *   1. The program expects a valid AccuWeather location code as a command-line argument.
 *   2. libcurl is used for making HTTP requests, so ensure that the libcurl library is installed.
 *   3. Compile the program with the -lcurl flag to link against the libcurl library.
 *   4. The METRIC macro can be toggled (0 for non-metric, 1 for metric) to control the unit of measurement.
 *   5. The program outputs the current weather information to the console.
 *   6. Error messages will be displayed in case of failures during URL construction, libcurl initialization,
 *      data fetching, or data processing.
 *   7. The program uses dynamic memory allocation to store the fetched data.
 *
 * Author: Clay Grace
 * Date: [Current Date]
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

#define METRIC 0

// Struct to store data fetched from the web
typedef struct {
    char *data;
    size_t size;
} MemoryData;

// Callback function to handle writing data received from libcurl
size_t write_callback(void *ptr, size_t size, size_t nmemb, MemoryData *mem) {
    size_t total_size = size * nmemb;
    
    // Reallocate memory to store the additional data received
    mem->data = realloc(mem->data, mem->size + total_size + 1);
    if (mem->data == NULL) {
        printf("Error: Memory allocation failed.\n");
        return 0;
    }

    // Copy the received data into the MemoryData struct
    memcpy(&(mem->data[mem->size]), ptr, total_size);
    mem->size += total_size;
    mem->data[mem->size] = '\0'; // Null-terminate the data

    return total_size;
}

// Function to fetch weather information from AccuWeather
void get_weather(const char *location_code) {
    // URL to fetch weather data
    char url[100];
    snprintf(url, sizeof(url), "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=%d&locCode=%s", METRIC, location_code);

    // Make a GET request to the URL using libcurl
    CURL *curl = curl_easy_init();
    if (curl) {
        MemoryData data;
        data.data = malloc(1); // Initialize data with size 1
        data.size = 0;

        // Set libcurl options
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &data);
        
        CURLcode res = curl_easy_perform(curl);

        if (res == CURLE_OK) {
            // Look for "<title>Currently: " and extract the weather information after it
            const char *start_tag = "<title>Currently: ";
            char *weather_start = strstr(data.data, start_tag);
            
            if (weather_start) {
                weather_start += strlen(start_tag);
                char *weather_end = strchr(weather_start, '<');
                
                if (weather_end) {
                    *weather_end = '\0'; // Null-terminate the weather information
                    printf("%s\n", weather_start);
                } else {
                    printf("Error: Could not find weather data.\n");
                }
            } else {
                printf("Error: Could not find weather data.\n");
            }
        } else {
            printf("Error: Could not fetch weather data.\n");
        }

        // Clean up resources
        free(data.data);
        curl_easy_cleanup(curl);
    } else {
        printf("Error: Could not initialize libcurl.\n");
    }
}

int main(int argc, char *argv[]) {
    // Check for the correct number of command-line arguments
    if (argc != 2) {
        printf("Usage: %s location_code\n", argv[0]);
        return 1;
    }

    // Fetch and display weather information
    get_weather(argv[1]);

    return 0;
}
