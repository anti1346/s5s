#!/bin/bash

### Color ###
COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_YELLOW="\e[33m"
BOLD_GREEN="\e[1;${COLOR_GREEN}m"
BOLD_YELLOW="\e[1;${COLOR_YELLOW}m"
ITALIC_RED="\e[3;${COLOR_RED}m"
COLOR_RESET="\e[0m"

### Function ###
collect_hardware_info() {
    local manufacturer=$(dmidecode -t system | awk -F': ' '/Manufacturer/{print $2}' | xargs | awk '{print $1}')
    
    case "$manufacturer" in
        HP|HPE)
            local vendor="HP"
            local product_name=$(dmidecode -t system | awk -F': ' '/Product Name/{print $2}' | xargs)
            local platform="Linux"
            ;;
        VMware)
            local vendor="VM"
            local product_name="VMware"
            local platform="Linux"
            ;;
        Stratus)
            local vendor="VM"
            local product_name="EverRun"
            local platform="Linux"
            ;;
        *)
            echo -e "${ITALIC_RED}Unknown Manufacturer. Please check:${COLOR_RESET}"
            echo "dmidecode -t system | grep 'Manufacturer'"
            echo "dmidecode -t system | grep 'Product Name'"
            echo "cat /etc/redhat-release"
            return
            ;;
    esac
    
    echo -e "$vendor\t$product_name\t$platform"
}

collect_os_info() {
    if [ -f /etc/redhat-release ]; then
        local os_version=$(awk '{print $3}' /etc/redhat-release | cut -d '.' -f1)
        local os_name=$(awk '{print $1, $4}' /etc/redhat-release | cut -d '.' -f1-2)
        local os_bit=$(getconf LONG_BIT)
        local cpu_cores=$(grep -c "model name" /proc/cpuinfo)
        local total_memory=$(dmidecode -t memory | awk '/Size: [0-9]+/ {sum+=$2} END {print sum/1024 " GB"}')
        local total_disk=$(fdisk -l | awk '/Disk \/dev/ {sum+=$3} END {print sum " GB"}')
        local active_nics=$(ip addr | grep -E 'eno|eth|ens|enp' | grep 'state UP' | wc -l)
        
        echo -e "$os_name\t$os_bit-bit\t$cpu_cores cores\t$total_memory RAM\t$total_disk\tNICs: $active_nics"
    else
        echo -e "${ITALIC_RED}Unable to determine OS details.${COLOR_RESET}"
    fi
}

collect_utilization_info() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%.1f%%", 100 - v}')
    local memory_usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    echo -e "CPU: $cpu_usage\tMemory: $memory_usage"
}

collect_apm_info() {
    local apache_version=$(httpd -v 2>/dev/null | head -n1 | awk -F'/' '{print $2}' | cut -d' ' -f1)
    [ -z "$apache_version" ] && apache_version="No Apache"

    local php_version=$(php -v 2>/dev/null | head -n1 | awk '{print $2}')
    [ -z "$php_version" ] && php_version="No PHP"

    local mysql_version=$(mysqladmin -V 2>/dev/null | awk '{print $6}' | cut -d',' -f1)
    [ -z "$mysql_version" ] && mysql_version="No MySQL"

    echo -e "Apache: $apache_version\tPHP: $php_version\tMySQL: $mysql_version"
}

### Main ###
local_ip=$(ip -4 a show $(ip route | awk '/default/ {print $5}') | awk '/inet/ {print $2}' | cut -d'/' -f1)
echo -e "\n${BOLD_YELLOW}$local_ip\t$HOSTNAME${COLOR_RESET}"

echo -e "\n${BOLD_GREEN}$(collect_hardware_info)\n$(collect_os_info)\n$(collect_utilization_info)${COLOR_RESET}"

echo -e "\n${BOLD_GREEN}$(collect_apm_info)${COLOR_RESET}"
