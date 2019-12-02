#!/bin/bash
trap "echo Interrupted; exit;" SIGINT SIGTERM

HOST_FILE="/etc/hosts"
BOX_PREFIX="k1-"
MODE="check"
RESULT="all"

declare -a BOX_IP_ARR
declare -a BOX_NAME_ARR

debug_msg(){
  if [ ${MODE} != "debug" ]; then 
    return;
  fi

  MSG="[DEBUG] $1"
  echo ${MSG}
}

ping_success(){
  BOX_IP=$1
  BOX_NAME=$2
  if [ ${RESULT} == "all" ] || [ ${RESULT} == "success" ]; then
    MSG="[SUCCESS] ${BOX_NAME} (${BOX_IP}) is reachable by ping"
    echo ${MSG}
  fi
}

ping_fail() {
  BOX_IP=$1
  BOX_NAME=$2
  if [ ${RESULT} == "all" ] || [ ${RESULT} == "fail" ]; then
    MSG="[FAIL] ${BOX_NAME} (${BOX_IP}) is not reachable by ping"
    echo ${MSG}
  fi
}

result_msg(){
  RES=$1
  BOX_IP=$2
  BOX_NAME=$3

  ## print out a message of successful ping
  if [ ${RES} == "success" ]; then
    ping_success ${BOX_IP} ${BOX_NAME}
  elif [ ${RES} == "fail" ]; then
    ping_fail ${BOX_IP} ${BOX_NAME}
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
      result_msg "success" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    elif [ $? -eq 1 ]; then
      result_msg "fail" ${BOX_IP_ARR[idx]} ${BOX_NAME_ARR[idx]}
    fi

    idx=$(( idx + 1 ))
    if [[ ${idx} == ${#BOX_IP_ARR[@]} ]];then
      break;
    fi
done
}

## Notice ##
# This script can be only working as expected in boxes on K-ONE playground
# Ping packets from All GIST boxes but outside of K-ONE playground are blocked by NetCS firewall 

usage() {
  echo "usage: $0 [-d] [-m all|success|fail]"
}


while getopts "dr:" arg; do
  case $arg in
  d)
    MODE="debug"
    ;;
  r)
    RESULT=${OPTARG}
    if [ ${RESULT} != "all" ] && [ ${RESULT} != "success" ] && [ ${RESULT} != "fail" ]; then
      usage
      exit 0
    fi
    ;;
  *)
    usage
    exit 0
    ;;
  esac
done

gather_box_ip_arr
gather_box_name_arr
ping_test
