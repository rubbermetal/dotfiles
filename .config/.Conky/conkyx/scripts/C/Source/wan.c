#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

struct response {
    char *data;
    size_t size;
};

size_t write_callback(char *ptr, size_t size, size_t nmemb, void *userdata) {
    struct response *resp = (struct response *)userdata;
    size_t total = size * nmemb;

    char *tmp = realloc(resp->data, resp->size + total + 1);
    if (!tmp) {
        return 0;
    }

    resp->data = tmp;
    memcpy(resp->data + resp->size, ptr, total);
    resp->size += total;
    resp->data[resp->size] = '\0';

    return total;
}

void get_wan_ip(char *wan_ip) {
    CURL *curl;
    CURLcode res;
    struct response resp = {NULL, 0};

    curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "Error initializing libcurl\n");
        return;
    }

    curl_easy_setopt(curl, CURLOPT_URL, "http://checkip.dyndns.org");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &resp);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);

    res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        fprintf(stderr, "Error fetching WAN IP: %s\n", curl_easy_strerror(res));
        curl_easy_cleanup(curl);
        free(resp.data);
        return;
    }

    if (resp.data) {
        char *ip_start = strchr(resp.data, ':');
        if (ip_start) {
            char *ip_end = strchr(ip_start, '<');
            if (ip_end) {
                *ip_end = '\0';
                strcpy(wan_ip, ip_start + 2);
            }
        }
    }

    curl_easy_cleanup(curl);
    free(resp.data);
}

int main() {
    char wan_ip[50] = {0};

    get_wan_ip(wan_ip);
    printf("%s\n", wan_ip);

    return 0;
}
