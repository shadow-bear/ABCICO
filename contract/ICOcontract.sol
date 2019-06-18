pragma solidity ^0.4.20;

import "./SecondERC20.sol";

//create an manager for token that would sale

contract ownerShip {
    address public owner;
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyowner(){
        require(msg.sender == owner);
        _;
    }
    function transferOwnerShip(address newOwner) public onlyowner {
        owner = newOwner;
    }
}

// ICO contract 
contract tokenSale is ownerShip {
    
    struct Buyer {
        uint256 ethSpent;
        uint256 tokenPurchased;
                                                        
    }
    
    MyToken public token;
    address public  ethAcceptAddr;
    uint8   public  currentAddrNum = 0;
    uint256 public  rate;           // 1ether = 1000ABC
    uint256 public  startLine;
    uint256 public  duration;
    uint256 public  saledTokenIntotal = 0;
    bool public  initialized = false;
    bool public  saleClosed = false;
    bool public  saleTargetReached = false;
    uint256 public  constant initialTokens = 10000 *10**18;
    
    //event BoughtTokens (address indexed to, uint256 value);
    //event backEth (address backer, uint amount, bool isSaled);
    //mapping(address => uint256) public balances;
    //mapping(address => uint256) public tokens;
    mapping(address => Buyer)   public PurchaseInfo;
    address[] internal buyerAddress;
    
    
    
  /* the manager set ethAcceptAddr,rate,startLine,duration for ICO*/
  
    function setTokenAddr(address _tokenAddr) onlyowner public {
        require(_tokenAddr != 0);
        token = MyToken(_tokenAddr);
    }
    
    
    function setEthAcceptAddr(address _setAddr) public onlyowner returns(bool success){
        require(_setAddr != 0);
        ethAcceptAddr = _setAddr;
        return true;
    }
    
    function setTokenRate (uint256 _setRate) public onlyowner returns(bool success) {
        rate  = _setRate;
        return true;
    }
    
    function setStartLine (uint256 _setLine) public onlyowner returns(bool success) {
        //require (_setLine != 0);
        startLine = _setLine;
        return true;
    }
    
    function setDuration (uint _setminutes) public onlyowner returns(bool success) {
        require(_setminutes >=0);
        duration = _setminutes;
        return true;
    }
    
    // Initialize the contract
    function initialize() public onlyowner {
        require(initialized == false);
        require(tokenAvailable() == initialTokens);
        initialized = true;
        
    }
    //Query the number of tokens in the contract account at this time
    function tokenAvailable() public constant returns(uint256) {
        return token.balanceOf(this);
        
    }
    
    
    //  Make sure sales is in progress
    modifier saleIsActive() {
        assert(isActive());
        _;
    }   
    
    function isActive() public view returns (bool){
        return 
            (initialized == true && now >= startLine && 
            now < startLine + duration * 1 minutes &&
            saleTargetReached == false
            ); 
        
    }
    
    //Determine if the deadline has passed
    modifier afterDeadline(){
        if (now >= startLine + duration * 1 minutes)
        _;
        
    }
    
    //Check if the target is completed during the sales period
    // function targetPreChecked()  saleIsActive public {
    //     if (saledTokenIntotal == initialTokens){
    //         saleTargetReached = true;
    //         saleClosed =true;
    //     }
        
    // }
    // Check if the target is completed after the deadline is exceeded
    function targetAfterChecked() onlyowner afterDeadline public  {
        if (saledTokenIntotal == initialTokens) {
            saleTargetReached = true;
        }
        saleClosed = true;
    } 

    //Purchase Tokens
    function purchaseToken() payable saleIsActive  public {
        require(saleClosed == false && saleTargetReached == false);
        Buyer storage currentBuyer = PurchaseInfo[msg.sender];
        uint256 usedEther = msg.value;
        uint256 purchasedTokens = usedEther * rate;
        require(saledTokenIntotal + purchasedTokens <= initialTokens);
        currentBuyer.ethSpent += usedEther;
        currentBuyer.tokenPurchased += purchasedTokens;
        saledTokenIntotal += purchasedTokens;
        //tokens[msg.sender] += purchasedTokens;
        //balances[ethAcceptAddr] += usedEther;
        buyerAddress.push(msg.sender);
    
    }  
    
  
    // The manager send tokens to buyers when the ICO suucessful
    function sendTokens() onlyowner afterDeadline public {
        require (saleTargetReached == true);
        for (uint i=0;i < buyerAddress.length; i++){
            address sendAddr = buyerAddress[i];
            uint tokenReadyToSend = PurchaseInfo[sendAddr].tokenPurchased;
            if (tokenReadyToSend > 0) {
                PurchaseInfo[sendAddr].tokenPurchased = 0;
                PurchaseInfo[sendAddr].ethSpent = 0;
                token.transfer(sendAddr,tokenReadyToSend);
                
            }
        }
        delete buyerAddress;
        require(ethAcceptAddr.send(this.balance));
        
    }
    
    
    //The manager return eth to buyers  when the ICO failed
    function backEth(uint8 backAddrAmount) onlyowner afterDeadline public {
        require (saleTargetReached == false);
        for (uint i=0;i < buyerAddress.length; i++){
            address backAddr = buyerAddress[i];
            uint ethReadyToSend = PurchaseInfo[backAddr].ethSpent;
            uint tokenReadyToBack = PurchaseInfo[backAddr].tokenPurchased;
            if (ethReadyToSend > 0) {
                token.transfer(owner,tokenReadyToBack);
                PurchaseInfo[backAddr].tokenPurchased = 0;
                backAddr.transfer(ethReadyToSend);
                PurchaseInfo[backAddr].ethSpent = 0;
            }
            
        }
        delete buyerAddress;
    }
    
    
    
    function acceptTokens() afterDeadline public {
        require(saleTargetReached == true);
        require(PurchaseInfo[msg.sender].tokenPurchased > 0);

    }
    
    
    //ICO failed to refund money by buyerself
    function returnEth() afterDeadline public {
        
    }
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
