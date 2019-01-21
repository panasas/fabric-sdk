const shim = require('fabric-shim');
const ClientIdentity = require('fabric-shim').ClientIdentity;

class Chaincode {

  async Init(stub) {
    console.info('Init');
    return shim.success();
  }

  async Invoke(stub) {
    let args = stub.getFunctionAndParameters();
    let method = this[args.fcn];
    try {
      let result = await method (stub, args.params);
      return shim.success(result);
    } catch (err) {
      console.log(err);
      return shim.error(err);
    }
  }

  async invoke(stub, args) {
    let key = args[0];
    let value = args[1];
    await stub.putState(key,value);
  }

  async query(stub, args) {
    let key = args[0];
    let result = await stub.getState(key);
    let cid = new ClientIdentity(stub);

    console.log(cid.getID());
    console.log(cid.getMSPID());
    console.log(cid.getX509Certificate());

    console.log(cid.getID().toString());
    console.log(cid.getMSPID().toString());
    console.log(cid.getX509Certificate().toString());
  
    console.log(result.toString());
    return result;
  }
}
shim.start(new Chaincode());
