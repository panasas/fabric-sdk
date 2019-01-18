#!/bin/bash
function generateOrdererOrg () {
    typeset orgDir=$1
    typeset orgName=$2
    typeset signCert=$3
    typeset signKey=$4

    typeset baseDir=$orgDir/$orgName
	typeset caDir=$baseDir/ca
	typeset tlscaDir=$baseDir/tlsca
	typeset orderersDir=$baseDir/orderers/orderer.$orgName
	typeset usersDir=$baseDir/users
	typeset mspDir=$baseDir/msp
    mkdir -p $baseDir $caDir $tlscaDir $orderersDir $usersDir $mspDir

    # Generate CA certificate
    typeset caKey=$caDir/ca.$orgName-key.pem
    typeset caCsr=$caDir/ca.$orgName-csr.pem
	typeset caCert=$caDir/ca.$orgName-cert.pem
    newCA $caDir ca.$orgName $signCert $signKey $caKey $caCsr $caCert "true" $orgName "NULL" "NULL"
    typeset caKey=$caDir/$(getSKI $caCert)"_sk"

    # Generate TLSCA certificate
    typeset tlscaKey=$tlscaDir/tlsca.$orgName-key.pem
    typeset tlscaCsr=$tlscaDir/tlsca.$orgName-csr.pem
	typeset tlscaCert=$tlscaDir/tlsca.$orgName-cert.pem
    newCA $tlscaDir tlsca.$orgName $signCert $signKey $tlscaKey $tlscaCsr $tlscaCert "true" $orgName "NULL" "NULL"
    typeset tlscaKey=$tlscaDir/$(getSKI $tlscaCert)"_sk"

    # Generate Admin certificate
    typeset admincacertsKey=$mspDir/admincerts/Admin@$orgName-key.pem
    typeset admincacertsCsr=$mspDir/admincerts/Admin@$orgName-csr.pem
	typeset admincacertsCert=$mspDir/admincerts/Admin@$orgName-cert.pem
    generateVerifyingMSP $mspDir $orgName $caCert $caKey $tlscaCert $admincacertsKey $admincacertsCsr $admincacertsCert "NULL"
    typeset admincacertsKey=$mspDir/admincerts/$(getSKI $admincacertsCert)"_sk"

    # Generate orderer
    generateNodes $orderersDir $orgName $caCert $caKey $tlscaCert $tlscaKey $admincacertsCert $admincacertsKey "orderer" "NULL"

    # Generate Admin
    typeset adminDir=$usersDir/Admin@$orgName
    mkdir -p $adminDir
    generateNodes $adminDir $orgName $caCert $caKey $tlscaCert $tlscaKey $admincacertsCert $admincacertsKey "Admin" "NULL"

    rm $admincacertsKey
}

function generatePeerOrg () {
    typeset orgDir=$1
    typeset orgName=$2
    typeset signCert=$3
    typeset signKey=$4
    typeset peerCount=$5
    typeset userCount=$6

    typeset baseDir=$orgDir/$orgName
	typeset caDir=$baseDir/ca
	typeset tlscaDir=$baseDir/tlsca
	typeset peersDir=$baseDir/peers
	typeset usersDir=$baseDir/users
	typeset mspDir=$baseDir/msp
    mkdir -p $baseDir $caDir $tlscaDir $peersDir $usersDir $mspDir

    # Generate CA certificate
    typeset caKey=$caDir/ca.$orgName-key.pem
    typeset caCsr=$caDir/ca.$orgName-csr.pem
	typeset caCert=$caDir/ca.$orgName-cert.pem
    newCA $caDir ca.$orgName $signCert $signKey $caKey $caCsr $caCert "true" $orgName "NULL" "NULL"
    typeset caKey=$caDir/$(getSKI $caCert)"_sk"

    # Generate TLSCA certificate
    typeset tlscaKey=$tlscaDir/tlsca.$orgName-key.pem
    typeset tlscaCsr=$tlscaDir/tlsca.$orgName-csr.pem
	typeset tlscaCert=$tlscaDir/tlsca.$orgName-cert.pem
    newCA $tlscaDir tlsca.$orgName $signCert $signKey $tlscaKey $tlscaCsr $tlscaCert "true" $orgName "NULL" "NULL"
    typeset tlscaKey=$tlscaDir/$(getSKI $tlscaCert)"_sk"

    # Generate Admin certificate
    typeset admincacertsKey=$mspDir/admincerts/Admin@$orgName-key.pem
    typeset admincacertsCsr=$mspDir/admincerts/Admin@$orgName-csr.pem
	typeset admincacertsCert=$mspDir/admincerts/Admin@$orgName-cert.pem
    generateVerifyingMSP $mspDir $orgName $caCert $caKey $tlscaCert $admincacertsKey $admincacertsCsr $admincacertsCert "NULL"
    typeset admincacertsKey=$mspDir/admincerts/$(getSKI $admincacertsCert)"_sk"

    # Generate peers
    typeset count=0

    while [[ $count -lt $peerCount ]]
	do
        typeset peerDir=$peersDir/peer$count.$orgName
        mkdir -p $peerDir
        generateNodes $peerDir $orgName $caCert $caKey $tlscaCert $tlscaKey $admincacertsCert $admincacertsKey "peer$count" "serverAuth,clientAuth"
        (( count+=1 ))
    done

    # Generate Admin
    typeset adminDir=$usersDir/Admin@$orgName
    mkdir -p $adminDir
    generateNodes $adminDir $orgName $caCert $caKey $tlscaCert $tlscaKey $admincacertsCert $admincacertsKey "Admin" "NULL"

    count=0
    while [[ $count -lt $userCount ]]
	do
        typeset userDir=$usersDir/User$count@$orgName
        mkdir -p $userDir
        generateNodes $userDir $orgName $caCert $caKey $tlscaCert $tlscaKey $admincacertsCert $admincacertsKey "User$count" "NULL"
        (( count+=1 ))
    done
    rm $admincacertsKey
}

function generateNodes () {
    baseDir=$1
    orgName=$2
    caCert=$3
    caKey=$4
    tlscaCert=$5
    tlscaKey=$6
    adminCert=$7
    adminKey=$8
    nodeType=$9
    extendedKeyUsage=${10}

    typeset tlsDir=$baseDir/tls
    typeset mspDir=$baseDir/msp
    mkdir -p $tlsDir $mspDir
    
    typeset type=`echo $nodeType | cut -b 1-4`

    typeset tlsKey=$tlsDir/$nodeType.$orgName-key.pem
    typeset tlsCsr=$tlsDir/$nodeType.$orgName-csr.pem
	typeset tlsCert=$tlsDir/$nodeType.$orgName-cert.pem

    if [[ $type == "Admi" || $type == "User" ]] ; then
        tlsKey=$tlsDir/$nodeType@$orgName-key.pem
        tlsCsr=$tlsDir/$nodeType@$orgName-csr.pem
	    tlsCert=$tlsDir/$nodeType@$orgName-cert.pem
    fi

    newCA $tlsDir $nodeType.$orgName $tlscaCert $tlscaKey $tlsKey $tlsCsr $tlsCert "false" "NULL" "NULL" $extendedKeyUsage
    typeset tlsKey=$tlsDir/$(getSKI $tlsCert)"_sk"

    if [[ $type == "orde" || $type == "peer" ]] ; then
        mv $tlsCert $tlsDir/"server.crt"
        mv $tlsKey $tlsDir/"server.key"
        cp $tlscaCert $tlsDir/"ca.crt"
    else
        mv $tlsCert $tlsDir/"client.crt"
        mv $tlsKey $tlsDir/"client.key"
        cp $tlscaCert $tlsDir/"ca.crt"
    fi
    
    generateLocalMSP $mspDir $orgName $caCert $caKey $tlscaCert $tlscaKey $adminCert $adminKey $nodeType $extendedKeyUsage
}

function generateLocalMSP () {
    typeset baseDir=$1
    typeset orgName=$2
    typeset caCert=$3
    typeset caKey=$4
    typeset tlscaCert=$5
    typeset tlscaKey=$6
    typeset adminCert=$7
    typeset adminKey=$8
    typeset nodeType=$9
    typeset extendedKeyUsage=${10}
	
    typeset admincertsDir=$baseDir/admincerts
    typeset cacertsDir=$baseDir/cacerts
    typeset tlscacertsDir=$baseDir/tlscacerts
    typeset signcertsDir=$baseDir/signcerts
    typeset keystoreDir=$baseDir/keystore
    mkdir -p $admincertsDir $cacertsDir $tlscacertsDir $signcertsDir $keystoreDir

    typeset type=`echo $nodeType | cut -b 1-4`
    
    typeset nodeKey=$signcertsDir/$nodeType.$orgName-key.pem
    typeset nodeCsr=$signcertsDir/$nodeType.$orgName-csr.pem
	typeset nodeCert=$signcertsDir/$nodeType.$orgName-cert.pem

    if [[ $type == "Admi" || $type == "User" ]] ; then
        nodeKey=$signcertsDir/$nodeType@$orgName-key.pem
        nodeCsr=$signcertsDir/$nodeType@$orgName-csr.pem
        nodeCert=$signcertsDir/$nodeType@$orgName-cert.pem
    fi

    if [[ $type == "Admi" ]] ; then
        cp $adminCert $signcertsDir
        cp $adminKey $keystoreDir
    else
        newCA $signcertsDir $nodeType.$orgName $caCert $caKey $nodeKey $nodeCsr $nodeCert "false" "NULL" "NULL" $extendedKeyUsage
        nodeKey=$signcertsDir/$(getSKI $nodeCert)"_sk"
        mv $nodeKey $keystoreDir
    fi

    cp $adminCert $admincertsDir
    cp $caCert $cacertsDir
    cp $tlscaCert $tlscacertsDir
}

function generateVerifyingMSP () {
    typeset baseDir=$1
    typeset orgName=$2
    typeset caCert=$3
    typeset caKey=$4
    typeset tlscaCert=$5
    typeset admincacertsKey=$6
    typeset admincacertsCsr=$7
	typeset admincacertsCert=$8
    typeset extendedKeyUsage=$9

    typeset admincertsDir=$baseDir/admincerts
    typeset cacertsDir=$baseDir/cacerts
    typeset tlscacertsDir=$baseDir/tlscacerts
    mkdir -p $admincertsDir $cacertsDir $tlscacertsDir

    newCA $admincertsDir Admin@$orgName $caCert $caKey $admincacertsKey $admincacertsCsr $admincacertsCert "false" "NULL" "NULL" $extendedKeyUsage
    typeset admincacertsKey=$admincacertsDir/$(getSKI $admincacertsCert)"_sk"

    cp $caCert $cacertsDir
    cp $tlscaCert $tlscacertsDir
}

function newCA () {
    typeset baseDir=$1
    typeset orgName=$2
	typeset signCert=$3
	typeset signKey=$4
    typeset newKey=$5
    typeset newCsr=$6
	typeset newCert=$7
    typeset caFlag=$8
    typeset org=$9
	typeset orgUnit=${10}
    typeset extendedKeyUsage=${11}

    generateKey $newKey
	generateCSR $newKey $orgName $signCert $signKey $newCsr $caFlag $org $orgUnit $extendedKeyUsage
	generateCert $newCsr $signCert $signKey $newCert

    key=$baseDir/$(getSKI $newCert)"_sk"
    mv $newKey $key
    rm $newCsr
    sleep 1
}

function generateKey () {
	typeset keyFile=$1
	typeset tempKeyFile=$keyFile".temp"
	
	openssl ecparam -name prime256v1 -genkey -noout -out $tempKeyFile
	if 	[[ $? -ne 0 ]] ; then
		echo "Private key creation failed : $keyFile"
		exit 4
	fi

	openssl pkcs8 -topk8 -nocrypt -in $tempKeyFile -out $keyFile
	if 	[[ $? -ne 0 ]] ; then
		echo "Private key PKCS#8 format conversion failed : $keyFile"
		exit 4
	fi
    sleep 1
	rm $tempKeyFile
}

function generateCSR () {
	typeset keyFile=$1
	typeset CN=$2
	typeset rootCaCert=$3
	typeset rootCaKey=$4
	typeset csrFile=$5
	typeset caFlag=$6
	typeset org=$7
    typeset orgUnit=$8
    typeset extendedKeyUsage=$9

	cp $confFileTemplate $confFile
	sed -i "s,%%root_key,$rootCaCert," $confFile
	sed -i "s,%%root_cert,$rootCaKey," $confFile
	sed -i "s,%%caFlag,$caFlag," $confFile

    if [[ $extendedKeyUsage != "NULL" ]] ; then
        sed -i "s/%%extendedKeyUsage/$extendedKeyUsage/" $confFile
    else
        sed -i "s/%%extendedKeyUsage/anyExtendedKeyUsage/" $confFile
    fi

	if [[ $org != "NULL" && $orgUnit != "NULL" ]] ; then
		openssl req -new -config $confFile -extensions $extension -x509 -key $keyFile -out $csrFile -subj "/C=US/ST=California/L=San Francisco/CN=$CN/O=$org/OU=$orgUnit"
		RC=$?
	elif [[ $org != "NULL" ]] ; then
		openssl req -new -config $confFile -extensions $extension -x509 -key $keyFile -out $csrFile -subj "/C=US/ST=California/L=San Francisco/CN=$CN/O=$org" 
		RC=$?
	elif [[ $orgUnit != "NULL" ]] ; then
		openssl req -new -config $confFile -extensions $extension -x509 -key $keyFile -out $csrFile -subj "/C=US/ST=California/L=San Francisco/CN=$CN/OU=$orgUnit" 
		RC=$?
	else
		openssl req -new -config $confFile -extensions $extension -x509 -key $keyFile -out $csrFile -subj "/C=US/ST=California/L=San Francisco/CN=$CN" 
		RC=$?
	fi
	
	if 	[[ $RC -ne 0 ]] ; then
		echo "CSR creation failed : $csrFile"
		exit 4
	fi
    sleep 1
}

function generateCert () {
	typeset csrFile=$1
	typeset rootCaCert=$2
	typeset rootCaKey=$3
	typeset certFile=$4

	# echo "$rootCaCert"
	# echo "$rootCaKey"
	# echo "openssl x509 -days 365 -CAcreateserial -CAserial ca.seq -in $csrFile -CA $rootCaCert -CAkey $rootCaKey -out $certFile"
	openssl x509 -days 365 -CAcreateserial -CAserial ca.seq -in $csrFile -CA $rootCaCert -CAkey $rootCaKey -out $certFile > /dev/null
	if 	[[ $? -ne 0 ]] ; then
		echo "Certificate creation failed : $certFile"
		exit 4
	fi
    sleep 1
}

function getSKI () {
	ski=$(openssl x509 -noout -text -in $1 | grep -A1 "Subject Key Identifier"  | awk  -F 'X509v3 Subject Key Identifier:' '{print tolower($1)}' | sed 's/://g')
	if [[ $? -ne 0 ]] ; then
		echo "Extracting Subject key identifier from cert $1 failed!"
	fi
	echo $ski
}


export rootCert=$1
export rootKey=$2
export confFileTemplate=$3
export configTemplate=$4
export confFile=$PWD/openssl.cnf
export extension="v3_intermediate_ca"

workDir=$PWD
cryptoDir=$PWD/crypto-config
ordererDir=$PWD/crypto-config/ordererOrganizations
peerDir=$PWD/crypto-config/peerOrganizations

if [[ -d $cryptoDir ]] ; then
	rm -rf $cryptoDir
fi
mkdir -p $cryptoDir $ordererDir $peerDir

generateOrdererOrg $ordererDir example.com $rootCert $rootKey
generatePeerOrg $peerDir org1.example.com $rootCert $rootKey 2 2
generatePeerOrg $peerDir org2.example.com $rootCert $rootKey 2 2



