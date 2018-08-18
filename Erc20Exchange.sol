pragma solidity 0.4.24;
import "../utils/usingOraclize.sol";

contract Erc20Exchange is usingOraclize {
    address private _owner;
    uint batEthPrice; 
    uint gntEthPrice;
    uint gntBatPrice;
    
    //mapping - how much user has both tokens on Erc20Exchange
    mapping(address => uint) public batBalances; //how much he transferred
    mapping(address => uint) public gntBalances;

    modifier isOwner {
        require(_owner == msg.sender, "must be owner");
        _;
    }
    
    constructor() public payable {
        _owner = msg.sender;
    //    updateBat(); // call this on transfer
    // updateGnt();
    }

    function setUserGntBalance(address user, uint amount) public isOwner {
        gntBalances[user] = amount;
    }
    
    function setUserBatBalance(address user, uint amount) public isOwner {
        batBalances[user] = amount;    
    }
    
    function sellBat(uint amount) {
        require(batBalances[msg.sender] >= amount);
        // check if user has enough funds
        // amount should be less (99,99%)
        // call the transfer on the Bat contract (transfer from xchange account to user account)
    }
    
    function sellGnt() {
        
    }
    
    function __callback(string result) public {
        // TODO: 2 callbacks?
        require(msg.sender == oraclize_cbAddress());
        batEthPrice = parseInt(result, 2); 
        
        gntBatPrice = gntEthPrice / batEthPrice; 
    }

    function updateBat() public payable {
        // TODO: right endpoint
        oraclize_query("URL", "xml(https://www.fueleconomy.gov/ws/rest/fuelprices).fuelPrices.lpg");
    }
    
    function updateGnt() public payable {
        // TODO: right endpoint
        oraclize_query("URL", "xml(https://www.fueleconomy.gov/ws/rest/fuelprices).fuelPrices.lpg");
    }
}