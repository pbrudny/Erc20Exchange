pragma solidity 0.4.24;
import "../utils/usingOraclize.sol";

contract Erc20Exchange is usingOraclize {
    address private _owner;
    address public gntAddress;
    address public batAddress;

    uint batEthPrice; 
    uint gntEthPrice;
    uint gntBatPrice;
    
    // mapping - how much both tokens user has on Erc20Exchange
    mapping(address => uint) public batBalances;
    mapping(address => uint) public gntBalances;

    modifier isOwner {
        require(_owner == msg.sender, "must be an owner");
        _;
    }
    
    enum oraclizeState { ForBat, ForGnt }
    
    struct oraclizeCallback {
        oraclizeState oState;
    }
    
    mapping (bytes32 => oraclizeCallback) public oraclizeCallbacks;
    
    event SellingBat(address user, uint amount);
    event SellingGnt(address user, uint amount);
    
    constructor(address _gntAddress, address _batAddress) public payable {
        _owner = msg.sender;
        gntAddress = _gntAddress;
        batAddress = _batAddress;
    }

    function setUserGntBalance(address user, uint amount) public isOwner {
        gntBalances[user] = amount;
    }
    
    function setUserBatBalance(address user, uint amount) public isOwner {
        batBalances[user] = amount;    
    }
    
    // call the transfer on the Gnt contract (transfer from exchange account to the user account)
    function sellBat(uint _batAmount) public {
        require(batBalances[msg.sender] >= _batAmount, "not enough balance");
        updateBat();
        updateGnt();
        // TODO: we need to make sure the price is the latest
        
        gntBatPrice = gntEthPrice / batEthPrice; 
        uint gntAmount = batGntPrice * 0.999 * _batAmount; // The fee is 0.1 % 

        // TODO: check the gnt balance
        if (transferGnt(gntAmount)) {
            batBalances[msg.sender] -= _batAmount; //TODO: add underflow protection
            emit sellBat(msg.sender, _batAmount);
        }
    }
    
    function sellGnt() public {
        // same as sellBat()
    }
    
    function transferGnt(uint _amount) public returns (bool answer) {
        bytes4 sig = batAddress.call(bytes4(keccak256("transfer(address, uint)")), msg.sender, _amount);
        
        // TODO: adjust this to get a result from the contract without using ABI
        // See: https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr, sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(
              15000, // gas limit
              sload(gntAddress_slot),  // to addr. append var to _slot to access storage variable
              0, // not transfer any ether
              ptr, // Inputs are stored at location ptr
              0x24, // Inputs are 36 bytes long
              ptr,  //Store output over input
              0x20) //Outputs are 32 bytes long
            
            if eq(result, 0) {
                revert(0, 0)
            }
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }
    
    function __callback(bytes32 _myid, string _result) public {
        require (msg.sender == oraclize_cbAddress(), "wrong sender");
        oraclizeCallback memory o = oraclizeCallbacks[myid];
        if (o.oState == oraclizeState.ForBat) {
            batEthPrice = parseInt(result, 2); //TODO: should be float
        } else if(o.oState == oraclizeState.Forxpected) {
            gntEthPrice = parseInt(result, 2);
        }
    }
    
    function updateBat() public payable {
        // TODO: fix endpoint
        bytes32 queryId = oraclize_query("URL","xml(https://api.bitfinex.com/v2/book/tBATETH/P0)");
        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.ForBat);
    }
    
    function updateGnt() public payable {
        // TODO: fix endpoint
        bytes32 queryId = oraclize_query("URL","xml(https://api.bitfinex.com/v2/book/tGNTETH/P0)");
        oraclizeCallbacks[queryId] = oraclizeCallback(oraclizeState.ForGnt);
    }
}