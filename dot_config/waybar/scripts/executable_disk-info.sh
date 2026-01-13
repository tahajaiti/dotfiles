#!/bin/bash

info=$(df -h / | tail -1 | awk '{print "Used: "$3" / "$2" ("$5")\nFree: "$4}')

notify-send "Disk Usage" "$info" -t 5000