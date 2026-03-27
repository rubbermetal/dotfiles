#include <stdio.h>
#include <time.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Function to calculate moon phase
double moon_phase(int year, int month, int day) {
    // Convert the year, month, and day to Julian date
    double JD = 367.0 * year - floor(7.0 * (year + floor((month + 9.0) / 12.0)) / 4.0) + floor(275.0 * month / 9.0) + day + 1721013.5;

    // Calculate the number of days since the last new moon (known new moon on January 6, 2000)
    double days_since_new = JD - 2451550.1;

    // Calculate the number of new moons that have occurred since the reference new moon
    double new_moons = days_since_new / 29.53058867;

    // Calculate the moon's age
    double moon_age = new_moons - floor(new_moons);

    return moon_age;
}

int main() {
    // Get current date
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    int year = tm.tm_year + 1900;
    int month = tm.tm_mon + 1;  // Months are zero-based in C's time.h
    int day = tm.tm_mday;

    // Calculate moon phase
    double phase = moon_phase(year, month, day);

    // Convert phase to angle in degrees
    double angle = phase * 360.0;

    // Calculate the moon's illumination
    double illumination = 100 * fabs(0.5 * (1 - cos(angle * M_PI / 180.0)));

    if (angle < 11.25 || angle >= 348.75) {
        printf("New Moon %.1f%%\n", illumination);
    } else if (angle < 78.75) {
        printf("Waxing Crescent %.1f%%\n", illumination);
    } else if (angle < 101.25) {
        printf("First Quarter %.1f%%\n", illumination);
    } else if (angle < 168.75) {
        printf("Waxing Gibbous %.1f%%\n", illumination);
    } else if (angle < 191.25) {
        printf("Full Moon %.1f%%\n", illumination);
    } else if (angle < 258.75) {
        printf("Waning Gibbous %.1f%%\n", illumination);
    } else if (angle < 281.25) {
        printf("Last Quarter %.1f%%\n", illumination);
    } else if (angle < 348.75) {
        printf("Waning Crescent %.1f%%\n", illumination);
    }

    return 0;
}
