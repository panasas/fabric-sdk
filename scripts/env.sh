#!/bin/bash
###############################
# Program: env.sh
# Author: Varun Yadavalli
###############################

function usage() {
  echo "Usage:"
  echo "       env.sh set <MSPID> <DOMAIN> <PEER NO>"
  echo "       env.sh get"
}

function setEnv() {
  CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}/users/Admin@${DOMAIN}/msp 
  CORE_PEER_ADDRESS="${PEER}.${DOMAIN}:7051" 
  CORE_PEER_LOCALMSPID=${MSPID} 
  CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}/peers/${PEER}.${DOMAIN}/tls/ca.crt 
  echo "export CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
  echo "export CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
  echo "export CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
  echo "export CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"
}

function getEnv() {
  echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
  echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
  echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
  echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"
}

if [[ $1 == "set" ]] ; then
  if [[ $# != 4 ]]; then 
    usage
    exit 4
  fi
  MSPID=$2
  DOMAIN=$3
  PEER=$4
  setEnv
elif [[ $1 == "get" ]]; then
  getEnv
else
  echo "Inavlid Option"
  usage
fi

