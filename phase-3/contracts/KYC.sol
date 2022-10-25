// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KYC{
    struct Customer {
        string username; //unique
        string customerData; //data entered to approved of KYC
        bool kycStaus; //denotes the KYC status
        uint downVotesOfCustomer; //down votes of a customers
        uint upVotesOfCustomer; //up vaotes of a customer
        address bank; // bank which added the customer
    }

    struct Bank{
        string name;  //unique
        address ethAddress;  // address of the bank
        uint complaintReport; //complaints reported on the bank
        uint kycCount; // kyc count of bank
        bool isAllowedTovote; // banks which are allowed to vote as set to true else false
        string regNo; //registration number of the bank 
    }

    struct Request{
        string userName;  //unique
        address bankAddress; //bank that added the kyc request
        string customerData; // data has to be hashed        
    }

    address admin; //Admin address is saved on deployment
    uint totalBanks; //total number of banks

    // this function is added where only admin can perform some action
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "You must have admin priviledges to run this"
        );
        _;
    }

    //banks which are allowed to vote
    modifier bankAllowedToVote() {
        require(
            BankInfo[msg.sender].isAllowedTovote == true,
            "Your right to vote has been revoked. Please contact admin."
        );
        _;
    }

    // all the banks present in the network
    modifier banksInTheList() {
        require(
            added_banks[msg.sender] == true,
            "you are not still approved by the administrator.. please contact admin"
        );
        _;
    }

    //for keeping track of username to struct
    mapping (string => Customer) customersInfo; //customer userName -> customer Struct
    mapping (address => Bank) BankInfo; //bank username -> Bank struct
    mapping (string => Request) KycRequest; //username -> request struct

    // to keep track of upVote and downVote
    mapping (string => mapping (address => uint)) upVotes;  //userName -> address -> upVoteCount
    mapping (string => mapping (address => uint)) downVotes; //userName -> address -> downVotecount

    //to maintain uinqueness of the banks
    mapping (address => bool) added_banks;
    mapping (address => bool) registrationNumberBanks;
    mapping (address => bool) bankNames;

    // when contract is deployed , the address is assigned to the constructor
    constructor(){
        admin = msg.sender;
    }

    // bank interface 
    // to add KYC request from bank to blockchain
    function addResquest(string memory _userName, string memory _customerData) public {
        require(!(KycRequest[_userName].bankAddress == msg.sender), "Request already exist in the banks KYC!" );
        KycRequest[_userName].userName = _userName;
        KycRequest[_userName].bankAddress = msg.sender;
        KycRequest[_userName].customerData = _customerData;

    } 

    //to add customers to the blockchain
    function addCustomer(string memory _userName, string memory _customerData) public banksInTheList{
        require(customersInfo[_userName].bank != msg.sender, "This address exist! so try modifying it");
        customersInfo[_userName].username = _userName;
        customersInfo[_userName].customerData = _customerData;
        customersInfo[_userName].bank = msg.sender;
    }

    //to remove request from the blockchain
    function removeRequest( string memory _userName) public {
        require((KycRequest[_userName].bankAddress == msg.sender),"The request is not found! please add the request");
        require( (keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this accounr doestn exist");
        delete KycRequest[_userName];
        removeRequest(_userName);
    }

    // to view customers by providing the userName
    function viewCustomer( string memory _userName) public view banksInTheList returns(Customer memory){
        return customersInfo[_userName];
    }

    //to modify the customer which is already present
    function modifyCustomer( string memory _userName , string memory _customerData) public banksInTheList{
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this accounr doestn exist please create one!");
        customersInfo[_userName].username = _userName;
        customersInfo[_userName].customerData = _customerData;
        customersInfo[_userName].bank = msg.sender;
    }
    
    //to upVote the customer by the bank
    function upVoteByBank(string memory _userName) public banksInTheList bankAllowedToVote{
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this account doestn exist please create one!");
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(KycRequest[_userName].userName))), "this user hasnt created a KYC request yet!");
        require(upVotes[_userName][msg.sender] == 0, "You have already upvoted voted !!");
        require(!(downVotes[_userName][msg.sender] == 1) , "You have already downvoted , so you cant upload. please remove it");
        customersInfo[_userName].upVotesOfCustomer++;
        upVotes[_userName][msg.sender] = 1;
    }

   // remote the upvote of the bank
    function removeUpvoteByBank(string memory _userName) public banksInTheList bankAllowedToVote{
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this account doestn exist please create one!");
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(KycRequest[_userName].userName))), "this user hasnt created a KYC request yet!");
        require(upVotes[_userName][msg.sender] == 1, "You havent voted yet to remove it");
        customersInfo[_userName].upVotesOfCustomer--;
        upVotes[_userName][msg.sender] = 0;
    }

    //to down vote the customer by the bank
    function DownVoteByBank(string memory _userName) public banksInTheList bankAllowedToVote{
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this account doestn exist please create one!");
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(KycRequest[_userName].userName))), "this user hasnt created a KYC request yet!");
        require(downVotes[_userName][msg.sender] == 0, "You have already down voted !!");
        require(!(upVotes[_userName][msg.sender] == 1) , "You have already up voted , so you cant down vote. please remove it");
        customersInfo[_userName].downVotesOfCustomer++;
        downVotes[_userName][msg.sender] = 1;
    }

    //remove the down vote of the customer
    function removeDownvoteByBank(string memory _userName) public banksInTheList bankAllowedToVote{
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(customersInfo[_userName].username))), "this account doestn exist please create one!");
        require((keccak256(abi.encodePacked(_userName)) == keccak256(abi.encodePacked(KycRequest[_userName].userName))), "this user hasnt created a KYC request yet!");
        require(downVotes[_userName][msg.sender] == 1, "You havent voted yet to remove it");
        customersInfo[_userName].downVotesOfCustomer--;
        downVotes[_userName][msg.sender] = 0;
    }

    //returns the number of complaints on the bank by other banks
    function getBankCompliants (address _bankAddress) public view banksInTheList returns(uint){
        require(BankInfo[_bankAddress].ethAddress == _bankAddress, "Address is not correct!");
        return BankInfo[_bankAddress].complaintReport;
    }

    //returns bank details of a particular bank
    function getBankDetails( address _bankAddress) public view banksInTheList returns(Bank memory){
        return BankInfo[_bankAddress];
    }

    // reports if the bank is validating invalid KYCs
    function reportBank (address _bankAddress) public banksInTheList {
        require(BankInfo[_bankAddress].ethAddress == _bankAddress, "Addres is not correct!");
        BankInfo[_bankAddress].complaintReport++;
        uint condition1 = BankInfo[_bankAddress].complaintReport * 100;
        uint condition2 = 33 * totalBanks;
        if (condition1 > condition2) {
            BankInfo[_bankAddress].isAllowedTovote = false;
        }
    }

    //Admin interface
    //able to add banks to the network
    function AddBank(string memory _bankName, address _bankAddress, string memory _bankRegistration) public onlyAdmin{
        require( added_banks[_bankAddress] == false , "Banks is already added in the list");
        require( registrationNumberBanks[_bankAddress] == false , "This registration number is already taken");
        require( bankNames[_bankAddress] == false , "This bank already exist on the blockchain");

        BankInfo[_bankAddress].name = _bankName;
        BankInfo[_bankAddress].ethAddress = _bankAddress;
        BankInfo[_bankAddress].complaintReport = 0;
        BankInfo[_bankAddress].kycCount = 0;
        BankInfo[_bankAddress].isAllowedTovote = true;
        BankInfo[_bankAddress].regNo = _bankRegistration;
        
        added_banks[_bankAddress] = true;
        registrationNumberBanks[_bankAddress] = true;
        bankNames[_bankAddress] = true;
        totalBanks++;
    }

    //remove the banks from the network
    function removeBank(address _bankAddress) public onlyAdmin{
        require( BankInfo[_bankAddress].ethAddress == _bankAddress , "This bank address doesn't exist");
        delete BankInfo[_bankAddress];
        totalBanks--;
    }

    //modify the access of up voting and down voting 
    function ModifyBankAccess(address _bankAddress, bool _canBankvote) public onlyAdmin{
        require( BankInfo[_bankAddress].ethAddress == _bankAddress , "This bank address doesn't exist");
        BankInfo[_bankAddress].isAllowedTovote = _canBankvote;
    }
}