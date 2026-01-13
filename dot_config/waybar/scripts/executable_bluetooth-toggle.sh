#!/bin/bash

if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off && \
        notify-send "Bluetooth" "Turned off" -t 1500
else
    bluetoothctl power on && \
        notify-send "Bluetooth" "Turned on" -t 1500
fi