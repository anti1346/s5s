#!/bin/bash

# 출력 스타일링용 색상 코드
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No color

# current IP 주소를 가져와 Network ID와 Host ID로 분리
current_ip=$(dig @resolver1.opendns.com myip.opendns.com +short)
network_id=$(echo "$current_ip" | cut -d . -f1-3)
host_id=$(echo "$current_ip" | cut -d . -f4)

# 비밀번호를 업데이트할 사용자 목록
user_list=$@

# 각 사용자의 비밀번호를 업데이트하는 기능
update_passwords() {
  for user in $user_list; do
    case $user in
      user1) password_base="aaa" ;;
      user2) password_base="bbb" ;;
      root)  password_base="ccc" ;;
      *)
        echo -e "${RED}Unknown user name '${user}'.${NC}"
        exit 127
        ;;
    esac

    # Combine password base with network and host ID
    final_password="${password_base}${nid}${hid}"
    
    # Update the password for the user
    echo "$final_password" | passwd --stdin "$user" > /dev/null 2>&1
    echo -e "${GREEN}$user password has been updated.${NC}"
    
    # Provide SSH connection string
    echo -e "${RED}sshpass -p'$final_password' ssh $user@$current_ip -oStrictHostKeyChecking=no${NC}"
  done
}

# Network ID를 확인하고 적절한 식별자를 설정
case $network_id in  
  111.111.111)
    nid='!!!'
    hid=$host_id
    update_passwords
    ;;
  222.222.222)
    nid='@@@'
    hid=$host_id
    update_passwords
    ;;
  10.10.10)
    nid=')!)'
    hid=$host_id
    update_passwords
    ;;
  10.10.20)
    nid=')@)'
    hid=$host_id
    update_passwords
    ;;
  192.168.0)
    nid=')))'
    hid=$host_id
    update_passwords
    ;;
  *)
    echo -e "${RED}Unknown Network ID (Netmask) '$network_id'.${NC}"
    ;;
esac
