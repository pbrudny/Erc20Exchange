pragma solidity 0.4.24;
import "../utils/usingOraclize.sol";

contract Erc20Exchange is usingOraclize {
    address private _owner;
    address public gntAddress;
    
    uint batEthPrice; 
    uint gntEthPrice;
    uint gntBatPrice;
    
    //mapping - how much user has both tokens on Erc20Exchange
    mapping(address => uint) public batBalances; //how much he transferred
    mapping(address => uint) public gntBalances;

    modifier isOwner {
        require(_owner == msg.sender, "must be an owner");
        _;
    }
    
    event SellingBat(address user, uint amount);
    event SellingGnt(address user, uint amount);
    
    constructor(address _gntAddress, address _batAddress) public payable {
        owner = msg.sender;
        gntAddress = _gntAddress;
        batAddress = _batAddress;
    }

    function setUserGntBalance(address user, uint amount) public isOwner {
        gntBalances[user] = amount;
    }
    
    function setUserBatBalance(address user, uint amount) public isOwner {
        batBalances[user] = amount;    
    }
    
    function sellBat(uint _amount) {
        // check if user has enough funds
        // amount should be less (99,9%)
        // get the last price
        // call the transfer on the Bat contract (transfer from xchange account to user account)
        uint fee = _amount * 0.001;
        require(batBalances[msg.sender] >= _amount, "not enough balance");
        updateBat();
        updateGnt();
        
        uint gntAmount = batGntPrice * (_amount - fee);
        if (transferBat(_amount)) {
            batBalances[msg.sender] -= _amount; //TODO: add underflow protection
            emit sellBat(msg.sender, amount);
        }
    }
    
    function sellGnt() {
        // same as selBat()
    }
    
    function transferBat(uint _amount) public returns (bool answer) {
        bytes4 sig = batAddress.call(
            bytes4(keccak256("transfer(address, uint)")), msg.sender, gntAmount);
        
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
              sload(dc_slot),  // to addr. append var to _slot to access storage variable
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
    
    function __callback(string result) public {
        // TODO: get 2 results same time?
        require(msg.sender == oraclize_cbAddress());
        batEthPrice = parseInt(result, 2); 
        gntEthPrice = parseInt(result, 2); 
        
        gntBatPrice = gntEthPrice / batEthPrice; 
    }

    function updateBat() public payable {
        // TODO: fix endpoint
        oraclize_query("URL", "xml(https://api.bitfinex.com/v2/book/tBATETH/P0)");
    }
    
    function updateGnt() public payable {
        // TODO: fix endpoint
        oraclize_query("URL", "xml(https://api.bitfinex.com/v2/book/tGNTETH/P0)");
    }
}