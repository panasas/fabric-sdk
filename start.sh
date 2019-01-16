#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

#docker-compose -f docker-compose.yml down
# exit
# docker-compose -f docker-compose.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb
docker-compose -f docker-compose.yml up -d

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@br.example.com/msp" peer0.br.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.br.example.com to the channel.
sleep 2
docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@br.example.com/msp" peer0.br.example.com peer channel join -b mychannel.block
# Join peer1.br.example.com to the channel.
#docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@br.example.com/msp" peer1.br.example.com peer channel join -b mychannel.block
# docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@br.example.com/msp" -e "peer0.br.example.com:7051" peer1.br.example.com peer channel join -b mychannel.block
sleep 2
docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@br.example.com/msp" -e "CORE_PEER_ADDRESS=peer1.br.example.com:7051" peer0.br.example.com peer channel join -b mychannel.block
