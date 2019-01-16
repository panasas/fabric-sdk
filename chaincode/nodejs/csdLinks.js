const shim = require('fabric-shim');
const util = require('util');

var Chaincode = class {

  // Initialize the chaincode
  async Init(stub) {
    console.info('========= Init =========');
    return shim.success();
  }

  async Invoke(stub) {
    let ret = stub.getFunctionAndParameters();
    console.info(ret);
    let method = this[ret.fcn];
    console.log ('method called is :' + ret.fcn)
    try {
      if (method === "invoke") {
        let payload = await invoke(stub, ret.params);
        return shim.success(payload);
      } else if (method === "query") {
        let payload = await query(stub, ret.params);
        return shim.success(payload);
      } else {
        console.log('no method of name:' + method + ' found');
        return shim.success();
      }        
    } catch (err) {
      console.log(err);
      return shim.error(err);
    }
  }

  async invoke(stub, args) {
    if (args.length != 2) {
      throw new Error('Incorrect number of arguments. Expecting 2');
    }

    let countryName = args[0];
    let countryInfo = args[1];
    if (!countryName) {
      throw new Error('countryName must not be empty');
    }
    if (!countryInfo) {
      throw new Error('countryInfo must not be empty');
    }
    // Write the states back to the ledger
    await stub.putState(countryName, countryInfo.toString());
  }

  async query(stub, args) {
    if (args.length != 1) {
      throw new Error('Incorrect number of arguments. Expecting 1');
    }
    let countryName = args[0];
    if (!countryName) {
      throw new Error('countryName must not be empty');
    }
    
    let jsonResp = {};
    let Avalbytes = await stub.getState(countryName);
    if (!Avalbytes) {
      console.info('Failed to get state for ' + countryName);
    }
    jsonResp.name = countryName;
    jsonResp.info = Avalbytes.toString();
    console.info('Query Response:');
    console.info(jsonResp);
    return Avalbytes;
  }

};
shim.start(new Chaincode());
