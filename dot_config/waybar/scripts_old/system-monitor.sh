#!/bin/bash
# filepath: /home/kyojin/.config/waybar/scripts/system-monitor.sh

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
cpu_int=${cpu_usage%.*}

# Get memory usage
mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')

# Get disk usage
disk_usage=$(df -h / | awk 'NR==2 {print int($5)}')

# Determine CPU color
if [ "$cpu_int" -gt 80 ]; then
    cpu_class="critical"
elif [ "$cpu_int" -gt 60 ]; then
    cpu_class="warning"
else
    cpu_class="normal"
fi

# Determine memory color
if [ "$mem_usage" -gt 80 ]; then
    mem_class="critical"
elif [ "$mem_usage" -gt 60 ]; then
    mem_class="warning"
else
    mem_class="normal"
fi

# Output JSON for waybar
echo "{\"text\":\"CPU: ${cpu_int}% | RAM: ${mem_usage}%\", \"class\":\"${cpu_class}\", \"tooltip\":\"CPU: ${cpu_int}%\\nRAM: ${mem_usage}%\\nDisk: ${disk_usage}%\"}"