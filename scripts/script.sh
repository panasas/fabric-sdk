#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo

echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH="github.com/chaincode/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

if [ "$LANGUAGE" = "java" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh


createChannel() {
	setGlobals 0 1

	set -x
	peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	res=$?
	set +x

	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1; do
	    for peer in 0 1; do
	   	setGlobals $peer $org
		joinChannelWithRetry $peer $org
		echo "===================== peer ${CORE_PEER_ADDRESS} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for BR..."
updateAnchorPeers 0 1
#echo "Updating anchor peers for BMW..."
#updateAnchorPeers 0 2
#echo "Updating anchor peers for DTCC..."
#updateAnchorPeers 0 3

#Install chaincode 
echo "Installing chaincode on peer0.br..."
installChaincode 0 1
# echo "Install chaincode on peer0.bmw..."
# installChaincode 0 2
# echo "Install chaincode on peer0.dtcc..."
# installChaincode 0 3

echo "Installing chaincode on peer1.br..."
installChaincode 1 1
# echo "Install chaincode on peer1.bmw..."
# installChaincode 1 2
# echo "Install chaincode on peer1.dtcc..."
# installChaincode 1 3

# Instantiate chaincode on peer0.br
echo "Instantiating chaincode on peer0.br..."
instantiateChaincode 0 1

echo
echo "========= All GOOD, build execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
