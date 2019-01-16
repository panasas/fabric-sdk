package main  

import  (
	"fmt"
	"time"
	"encoding/json"
	"strconv"	
	"bytes"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type SimpleChaincode struct {
}

type request struct {
	DocType            string               `json:"DocType"`
	Organization       string               `json:"Organization"`
	UnixTimeStamp      string               `json:"UnixTimeStamp"`
	Cusip              string               `json:"Cusip"`
	PrivateCollection  string               `json:"PrivateCollection"`
	RequestInfo        issuerRequest        `json:"RequestInfo"`  
}

type issuerRequest struct {				
	CutOffDate         string               `json:"CutOffDate"`    
	Status             string               `json:"Status"`
//	BrokerForwardInfo  brokerForwardInfo[]  `json:"BrokerForwardInfo"`
}

type investorInfo struct {
	DocType            string               `json:"DocType"`
	IssuerOrgKey       string               `json:"IssuerOrgKey"`
	Broker             string               `json:"Broker"`
	InvestorName       string               `json:"InvestorName"`
	InversorEmail      string               `json:"InvestorEmail"`	
}

//type brokerForwardInfo struct {
//	Broker         string       `json:"Broker"`
//	unixTimeStamp  string       `json:"UnixTimeStamp"`
//	BrokerKey      string       `json:"BrokerKey"`
//}

type brokerRequest struct {
	DocType            string               `json:"DocType"`
	Broker             string               `json:"Broker"`
	UnixTimeStamp      string               `json:"UnixTimeStamp"`
	IssuerOrg          string               `json:"IssuerOrg"`
	IssuerOrgKey       string               `json:"IssuerOrgKey"`
	Cusip              string               `json:"Cusip"`
	PrivateCollection  string               `json:"PrivateCollection"`
	PrivateKey         string               `json:"PrivateKey"`
	RequestInfo        issuerRequest        `json:"RequestInfo"`  
} 

// Main function
func main() {
    err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

// Init intialize the chaincode 
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}

// Invoke - Our entry point for Invocations
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println("Invoke is running " + function)

	// Handle different functtions
	if function == "submitRequestToDTCC" {                   //create a new request
		return t.submitRequestToDTCC(stub, args)
	} else if function == "queryRequestByKey" {
		return t.queryRequestByKey(stub, args)
	} else if function == "queryRequestByOrg" {
		return t.queryRequestByOrg(stub, args)
	} else if function == "queryRequests" {
		return t.queryRequests(stub, args)
	} else if function == "forwardRequestToBrokers" {
		return t.forwardRequestToBrokers(stub, args)
	} else if function == "queryRequestHistory" {
		return t.queryRequestHistory(stub, args)
	} else if function == "sendInvestorData" {
		return t.sendInvestorData(stub, args)
	} else if function == "queryInvestorData" {
		return t.queryInvestorData(stub, args)
	}

	fmt.Println("invoke did not find func: " + function) //error
	return shim.Error("Received unknown function invocation")
}

// Submit Request
func (t *SimpleChaincode) submitRequestToDTCC(stub shim.ChaincodeStubInterface, args []string) peer.Response {	
	var err error

	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Requrie 4.\n \targ1:Org\n \targ2:Cusip\n \targ1:CutOffDate\n \targ1:PrivateCollection")
	}

	org               := args[0]  
	cusip             := args[1]
	cutOffDate        := args[2]
	privateCollection := args[3]
	status            := "open"
	objectType        := "IssuerInfoRequest"
	unixTimeStamp     := strconv.Itoa(int(time.Now().UnixNano()))
     
    //Create request object and marshal to JSON		
	jsonRequest := request{
							objectType, 
							org,
							unixTimeStamp,
							cusip,
							privateCollection,
							issuerRequest {
											cutOffDate,											
											status,         // Intially "open"
										  }, 
						}

	requestJSONasBytes, err := json.Marshal(jsonRequest)
	if err != nil {
		return shim.Error(err.Error())
	}

    //Save request to state 
    key := objectType + "-" + org + "-" + unixTimeStamp
	err = stub.PutState(key, requestJSONasBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("- end request")
	return shim.Success(nil)
}

func (t *SimpleChaincode) queryRequestByKey(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	var name, jsonResp string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting key")
	}

	name = args[0]
	valAsbytes, err := stub.GetState(name) //get the org from chaincode state
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + name + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"Organization does not exist: " + name + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}

func (t *SimpleChaincode) queryRequestByOrg(stub shim.ChaincodeStubInterface, args []string) peer.Response {

	if len(args) < 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	request := 	args[0]
	owner := args[1]

	queryString := fmt.Sprintf("{\"selector\":{\"DocType\":\"%s\",\"Organization\":\"%s\"}}", request, owner)

	//shim.Success(queryString)

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

func (t *SimpleChaincode) queryRequests(stub shim.ChaincodeStubInterface, args []string) peer.Response {

	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	request := 	args[0]

	queryString := fmt.Sprintf("{\"selector\":{\"DocType\":\"%s\"}}", request)

	//shim.Success(queryString)

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

func (t *SimpleChaincode) queryInvestorData(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	var jsonResp string
	var err error

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2.")
	}

	requestKey 			:= args[0]
	privateCollection 	:= args[1]

	valAsbytes, err := stub.GetPrivateData(privateCollection, requestKey) 
	
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get private details for " + requestKey + ": " + err.Error() + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"Error\":\"Request private details does not exist: " + requestKey + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}

func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		shim.Error(queryString)
		return nil, err
	}
	defer resultsIterator.Close()

	buffer, err := constructQueryResponseFromIterator(resultsIterator)
	if err != nil {
		return nil, err
	}

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

// ===========================================================================================
// constructQueryResponseFromIterator constructs a JSON array containing query results from
// a given result iterator
// ===========================================================================================
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) (*bytes.Buffer, error) {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return &buffer, nil
}

func (t *SimpleChaincode) forwardRequestToBrokers(stub shim.ChaincodeStubInterface, args []string) peer.Response {	
	
	if len(args) < 2 {
		return shim.Error("Incorrect number of arguments. Expecting at minimum 2")
	}

	issuerOrgKey := args[0]
	issuerRequestAsBytes, err := stub.GetState(issuerOrgKey)

	if err != nil {
		return shim.Error("Failed to get key:" + err.Error())
	} else if issuerRequestAsBytes == nil {
		return shim.Error("key does not exist")
	}

	requestToForward := request{}
	err = json.Unmarshal(issuerRequestAsBytes, &requestToForward) //unmarshal it aka JSON.parse()
	if err != nil {
		return shim.Error(err.Error())
	}

	docType 			:= "DTCCIssuerInfoRequest"
	issuerOrg 			:= requestToForward.Organization
	cusip 				:= requestToForward.Cusip
	cutOffDate 			:= requestToForward.RequestInfo.CutOffDate
	privateCollection 	:= requestToForward.PrivateCollection

	for i:=1; i<len(args); i++ {
		broker := args[i]
		unixTimeStamp := strconv.Itoa(int(time.Now().UnixNano()))
		brokerKey := docType + "-" + broker + "-" + unixTimeStamp
		
		brokerJsonRequest := &brokerRequest{ 
										docType,
										broker,
										unixTimeStamp,
										issuerOrg,
										issuerOrgKey,
										cusip,
										privateCollection,
										"",
										issuerRequest {
														cutOffDate,
														"open",
													},
								}

		brokerRequestJsonAsBytes, err := json.Marshal(brokerJsonRequest)
		if err != nil {
			return shim.Error(err.Error())
		}

		err = stub.PutState(brokerKey, brokerRequestJsonAsBytes)
		if (err != nil){
			return shim.Error(err.Error())
		}
	}

	//Forward the reuqest 	
	requestToForward.RequestInfo.Status = "Forwarded" 
	requestToForward.UnixTimeStamp      = strconv.Itoa(int(time.Now().UnixNano()))

	requestJsonAsBytes, err := json.Marshal(requestToForward)
	if err != nil {
			return shim.Error(err.Error())
	}

	err = stub.PutState(issuerOrgKey, requestJsonAsBytes) 
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("- end forwardReuqest (success)")
	return shim.Success(nil)
}


func (t *SimpleChaincode) sendInvestorData(stub shim.ChaincodeStubInterface, args []string) peer.Response {
	if len(args) != 4 {
		return shim.Error("Incorrect number of arguments. Expecting 4")		
	}
	
	broker  			:= args[0]
	brokerRequestKey 	:= args[1]
	issuerName 			:= args[2]
	issuerEmail 		:= args[3]
	docType 			:= "InvestorInfo"

	brokerRequestJsonAsBytes, err := stub.GetState(brokerRequestKey)
	if err != nil {
		return shim.Error("Failed to get key:" + err.Error())
	} else if brokerRequestJsonAsBytes == nil {
		return shim.Error("key does not exist")
	}

	brokerRequestJson := brokerRequest{}
	err =  json.Unmarshal(brokerRequestJsonAsBytes, &brokerRequestJson) //unmarshal it aka JSON.parse()
	if err != nil {
		return shim.Error(err.Error())
	}

	privateCollection 	:= brokerRequestJson.PrivateCollection
	issuerOrgKey		:= brokerRequestJson.IssuerOrgKey

	investorInfoJson := &investorInfo {
										docType,
										issuerOrgKey,
										broker,
										issuerName,
										issuerEmail,
									}

	investorInfoJsonAsBytes, err := json.Marshal(investorInfoJson)
	if err != nil {
		return shim.Error(err.Error())
	}

	privateDataKey := docType + "-" + broker + "-" + issuerOrgKey
	
	err = stub.PutPrivateData(privateCollection, privateDataKey, investorInfoJsonAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

// Update the DTCC request to sent and closed
	brokerRequestJson.RequestInfo.Status = "Sent and closed"
	brokerRequestJson.PrivateKey = privateDataKey
	brokerRequestJsonAsBytes, err =  json.Marshal(brokerRequestJson) 
	if err != nil {
		return shim.Error(err.Error())
	}

	err = stub.PutState(brokerRequestKey, brokerRequestJsonAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}
	
	fmt.Println("- end sendPrivateData (success)")
	return shim.Success(nil)
}


func (t *SimpleChaincode) queryRequestHistory (stub shim.ChaincodeStubInterface, args []string) peer.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	key := args[0]

	fmt.Printf("- start queryRequestHistory: %s\n", key)

	resultsIterator, err := stub.GetHistoryForKey(key)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing historic values for the key
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"TxId\":")
		buffer.WriteString("\"")
		buffer.WriteString(response.TxId)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Value\":")
		// if it was a delete operation on given key, then we need to set the
		//corresponding value null. Else, we will write the response.Value
		//as-is (as the Value itself a JSON marble)
		if response.IsDelete {
			buffer.WriteString("null")
		} else {
			buffer.WriteString(string(response.Value))
		}

		buffer.WriteString(", \"Timestamp\":")
		buffer.WriteString("\"")
		buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
		buffer.WriteString("\"")

		buffer.WriteString(", \"IsDelete\":")
		buffer.WriteString("\"")
		buffer.WriteString(strconv.FormatBool(response.IsDelete))
		buffer.WriteString("\"")

		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryRequestHistory returning:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}

