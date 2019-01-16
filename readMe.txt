peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n SubmitReq -l golang -v 1.0 -c '{"Args":["init"]}' -P 'OR ('Org1MSP.peer')'

peer chaincode invoke -o example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n SubmitReq -c '{"ARGS":["submitRequestToDTCC","BR","919666546644","21-11-18","BrCollection"]}'

submitRequestToDTCC","BR","919666546644","21-11-18","BrCollection"

docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/br.example.com/users/Admin@br.example.com/msp" cli 
peer chaincode install -n csdLinks -v 1.2 -p /opt/gopath/src/github.com/chaincode/nodejs -l node
docker exec -e "CORE_PEER_LOCALMSPID=BRMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/br.example.com/users/Admin@br.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n csdLinks -l node -v 1.2 -c '{"Args":["init"]}' -P "OR ('BRMSP.member')"


openssl ecparam -name prime256v1 -genkey -out temp.private.key
openssl pkcs8 -topk8 -nocrypt -in temp.private.key  -out private.key
openssl req -new -days 7500 -nodes -config openssl.cnf  -extensions v3_ca  -x509 -key private.key -out public.pem -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=broadridge.com"
