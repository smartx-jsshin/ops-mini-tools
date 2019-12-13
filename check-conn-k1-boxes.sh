#!/bin/bash
trap "echo Interrupted; exit;" SIGINT SIGTERM

HOST_FILE="/etc/hosts"
BOX_PREFIX="k1-"
DEBUG_MODE=1
PRINT_MODE="all"

SUCCESS_COLOR='\033[0;32m'
FAIL_COLOR='\033[0;31m'
NORMAL_COLOR='\033[0m'

declare -a BOX_IP_ARR
declare -a BOX_NAME_ARR

debug_msg(){
  if [ ${DEBUG_MODE} == 1 ]; then 
    return;
  fi

  MSG="[DEBUG] $1"
  echo ${MSG}
}

print_success_result(){
  TEST=$1
  BOX_IP=$2
  BOX_NAME=$3
  if [ ${PRINT_MODE} == "all" ] || [ ${PRINT_MODE} == "success" ]; then
    MSG="[${TEST}] ${SUCCESS_COLOR}[SUCCESS] ${BOX_NAME} (${BOX_IP})${NORMAL_COLOR}"
    echo -e ${MSG}
  fi
}

print_fail_result() {
  TEST=$1
  BOX_IP=$2
  BOX_NAME=$3
  if [ ${PRINT_MODE} == "all" ] || [ ${PRINT_MODE} == "fail" ]; then
    MSG="[${TEST}] ${FAIL_COLOR}[FAIL]\t ${BOX_NAME} (${BOX_IP})${NORMAL_COLOR}"
    echo -e ${MSG}
  fi
}

result_msg(){
  RES=$1
  TEST=$2
  BOX_IP=$3
  BOX_NAME=$4

  ## print out a message of successful ping
  if [ ${RES} == "success" ]; then
    print_success_result ${TEST} ${BOX_IP} ${BOX_NAME}
  elif [ ${RES} == "fail" ]; then
    print_fail_result ${TEST} ${BOX_IP} ${BOX_NAME}
  fi
}

gather_box_ip_arr(){
  idx=0
  BOX_IP_LIST=`cat ${HOST_FILE} | grep ${BOX_PREFIX} |  awk '{print $1}'`
  for BOX_IP in ${BOX_IP_LIST}; do
    BOX_IP_ARR[idx++]=${BOX_IP}
  done
}

gather_box_name_arr(){
  idx=0
  BOX_NAME_LIST=`cat ${HOST_FILE} | grep ${BOX_PREFIX} | awk '{print $2}'`
  for BOX_NAME in ${BOX_NAME_LIST}; do
    BOX_NAME_ARR[idx++]=${BOX_NAME}
  done
}

ping_test(){
  idx=0
  while true; do
    debug_msg "IDX: ${idx} / IP: ${BOX_IP_ARR[idx]} / NAME: ${BOX_NAME_ARR[idx]}"
    ping -c 1 -w 1 ${BOX_IP_ARR[idx]} >> /dev/null

    if [ $? -eq 0 ]; then
      result_msg "success" "Ping" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    elif [ $? -eq 1 ]; then
      result_msg "fail" "Ping" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    fi

    idx=$(( idx + 1 ))
    if [[ ${idx} == ${#BOX_IP_ARR[@]} ]];then
      break;
    fi
done
}

ssh_test(){
  SSH_PORT=22

  idx=0
  while true; do
    debug_msg "IDX: ${idx} / IP: ${BOX_IP_ARR[idx]} / NAME: ${BOX_NAME_ARR[idx]}"
    nc -z -w 1 ${BOX_IP_ARR[idx]} ${SSH_PORT} >> /dev/null

    if [ $? -eq 0 ]; then
      result_msg "success" "SSH" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    elif [ $? -eq 1 ]; then
      result_msg "fail" "SSH" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    fi

    idx=$(( idx + 1 ))
    if [[ ${idx} == ${#BOX_IP_ARR[@]} ]]; then
      break;
    fi
  done
  
}

## Notice ##
# This script can be only working as expected in boxes on K-ONE playground
# Ping packets from All GIST boxes but outside of K-ONE playground are blocked by NetCS firewall 

usage() {
  echo "usage: $0 [-d] [-p all|success|fail] [-m ping|ssh]"
}

gather_box_ip_arr
gather_box_name_arr

while getopts "dp::t:" arg; do
  case $arg in
  d)
    DEBUG_MODE=0
    ;;
  p)
    PRINT_MODE=${OPTARG}
    ;;
  t)
    TEST_MODE=${OPTARG}
    ;;
  *)
    usage
    exit 0
    ;;
  esac
done


shift $((OPTIND -1))

if [ ${PRINT_MODE} != "all" ] && [ ${PRINT_MODE} != "success" ] && [ ${PRINT_MODE} != "fail" ]; then
  usage
  exit 0
fi


case $TEST_MODE in
  "ping")
    ping_test
    ;;
  "ssh")
    ssh_test
    ;;
  *)
    usage
    exit 0
    ;;
esac
