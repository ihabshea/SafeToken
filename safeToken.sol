contract DCArbitration {
  function register(bytes32 _ToA, uint256 _trialDuration, string _URL)  public returns(bool);
  function fileCase(address _defendant, string _statement, string _title) public returns(uint256);
}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract libDCourt{
    using SafeMath for uint256;
    /*
        variables and instances
    */
    address DCAddr = 0x2f5cb57f0d2c0a96e4513f8e2dee40d22f3c8955;
    DCArbitration DCAcontract = DCArbitration(DCAddr);
    
    /*
        Modifiers
        
    */
    
    modifier onlyDCourt(){
        require(DCAddr == msg.sender);
        _;
    }

    /*
        Functions
    */
    
    function libDCourt(bytes32 _ToA, uint256 _trialDuration, string _URL) public{
        require(DCAcontract.register(_ToA, _trialDuration, _URL));
    }
    function fileCase(address _defendant, string _statement, string _title) internal returns(uint256){
        uint256 caseID = DCAcontract.fileCase(_defendant, _statement, _title);
        require(caseID > 0);
        return caseID;
    }
    function onVerdict(uint256 _caseID, bool verdict) public;
}
contract SafeToken is libDCourt, ERC20{
    /*
        Struct
    */
    struct Transfer_{
        uint timestamp;
        uint256 amount;
    }
    enum askType{
        STOLEN
    }
    
    struct Case{
        address accuser;
        address defendant;
        string title;
        askType ask;
        uint256 amount;
        bool decided;
        uint256 transactionID;
        bool verdict;        
    }
    /*
        variables
    */
    string name;
    string symbol;
    uint8 decimals;
    uint256 _totalSupply;
    uint256 lowerBound;
    uint256 safePercentage;
    /*
        mappings
    */
    mapping(address => uint256) balances;
    mapping(address => Transfer_[]) transfers;
    mapping (uint256 => Case) cases;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    /*
        events
    */
    event stolenTokens(address accuser, address _defendant, uint256 transactionID, uint256 caseID);
    event recoveredTokens(address accuser, address defendant, uint256 amount);
    
    /*
        Functions
    */
    
    function SafeToken(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply_, uint256 _lowerBound, uint256 _safePercentage) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _totalSupply_;
        balances[msg.sender] = _totalSupply_;
        lowerBound = _lowerBound;
        safePercentage = _safePercentage;
    }
    // function tempFreeze(address _defendant, uint amount) returns(bool){
    //     balances[_defendant] = balances[_defendant].sub(amount);
    //     return true;
    // }
    function recoverStolen(address _defendant, uint256 transactionID, string _statement) returns(uint256){
        require(transfers[_defendant][transactionID].amount > 0);
        require(transfers[msg.sender][transactionID].timestamp + 1 days < now );
        string memory _title = "Claim of stolen tokens";
        uint256 caseID = fileCase(_defendant,  _statement, _title);
        cases[caseID].accuser = msg.sender;
        cases[caseID].defendant = _defendant;
        cases[caseID].title = _title;
        cases[caseID].transactionID = transactionID;
        cases[caseID].amount = transfers[_defendant][transactionID].amount;
        cases[caseID].ask = askType.STOLEN;
        // tempFreeze(_defendant, transfers[_defendant][transactionID].amount);
        emit stolenTokens(msg.sender, _defendant,transactionID, caseID);
        return caseID;
    }
    function onVerdict(uint256 caseID, bool decision) public onlyDCourt{
        if(decision){
            if(cases[caseID].ask == askType.STOLEN){
                emit recoveredTokens(cases[caseID].accuser, cases[caseID].defendant, cases[caseID].amount);
            }
        }
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        uint count;
        bool disableTransaction;
        uint256 recentTransactions;
        for(uint i=0; i < transfers[msg.sender].length; i++){
            count +=1;
            if(transfers[msg.sender][i].timestamp + 1 days > now) break;
            recentTransactions = recentTransactions.add(transfers[msg.sender][i].amount);
            disableTransaction = true;
        }
        if(disableTransaction && _value > recentTransactions.div(10)){
            return false;
        }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool){
        require(balances[msg.sender] > value);
        require(to != address(0));
        uint count =0;
        uint recentTransactions = 0;
        bool disableTransaction;
        for(uint i=0; i < transfers[msg.sender].length; i++){
            count +=1;
            if(transfers[msg.sender][i].timestamp + 1 days > now) break;
            recentTransactions = recentTransactions.add(transfers[msg.sender][i].amount);
            disableTransaction = true;
        }
        if(disableTransaction && value > recentTransactions.div(10)){
            return false;
        }
        Transfer_ memory newtransfer;
        newtransfer.amount = value;
        newtransfer.timestamp = now;
        transfers[msg.sender][count] = newtransfer;
        balances[to] = balances[to].add(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        bool disableTransaction;
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
               uint count =0;
        uint recentTransactions = 0;
        for(uint i=0; i < transfers[msg.sender].length; i++){
            count +=1;
            if(transfers[msg.sender][i].timestamp + 1 days > now) break;
            recentTransactions = recentTransactions.add(transfers[msg.sender][i].amount);
            disableTransaction = true;
        }
        if( disableTransaction && _value > recentTransactions.div(10) ){
            return false;
        }
        Transfer_ memory newtransfer;
        newtransfer.amount = _value;
        newtransfer.timestamp = now;
        transfers[msg.sender][count] = newtransfer;
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        return true;
    }
}
