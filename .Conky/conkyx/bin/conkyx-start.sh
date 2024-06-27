#!/bin/bash

start_conky() {
    CONKYRC=~/.Conky/conkyx/config/conkyrc
    LOG_FILE=~/.Conky/conky.log
    MAX_LOG_ENTRIES=100
    if [ ! -f "$LOG_FILE" ]; then
        touch $LOG_FILE
    fi
    if [ $(wc -l < $LOG_FILE) -ge $MAX_LOG_ENTRIES ]; then
        echo "`date`: Log reached maximum entries, rotating log" >> $LOG_FILE
        tail -n $(( $MAX_LOG_ENTRIES / 2 )) $LOG_FILE > $LOG_FILE.tmp
        mv $LOG_FILE.tmp $LOG_FILE
    fi
    if [ -f "$CONKYRC" ]; then
        if ! pgrep -x "conky" > /dev/null; then
            echo "`date`: Starting Conky" >> $LOG_FILE
            conky --config $CONKYRC -d &
            if [ $? -ne 0 ]; then
                echo "`date`: Failed to start Conky with error code $?" >> $LOG_FILE
                exit 1
            else
                echo "`date`: Conky started successfully" >> $LOG_FILE
            fi
        else
            echo "`date`: Conky is already running" >> $LOG_FILE
            fi
    else
        echo "`date`: Error: Conky config file not found" >> $LOG_FILE
        exit 1
    fi
}

trap 'pkill conky; echo "`date`: Stopping Conky" >> $LOG_FILE; exit 0' INT TERM
start_conky
