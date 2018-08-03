pragma solidity ^0.4.19;

// Pig World Chain (aka PWC is a Plasma solution)
// We are under heavy development, and use ether for test environment.
// using the PICO (ERC-20 Token) for production Environment.

// PWC let the pig world platform is totally decentralized & p2p game.
// PWC preliminary estimate TPS: 10,000

//--------

//Roles in PWC
//verifier, player, dealer, challengeWithdrawal

//--------

//Main function in PWC
//submit header, deposite, withdraw, challenge, prove a challenge

//--------

//Process of player lifecycle
// 1. Player deposite.
// 2. Player Play Game & trasnfer token to someone.
// 3. Player apply to waithdraw
// 4. if 6 Verifier agree his application, then open to challenge(in 3 days).
// 5. Someone want to challenge, pay 1 ether and get more 3 days.
// 6. Verifier need to prove it or punish Verifier who had agree the waithdraw.
// 7. if challenger successful challenge get big bounty.

//--------

//TO DO LIST
// Game Result Challenge - Open Game, Play Game.
// Verifier commission distribution method.
// Function Event.


// Pig World Team.  https://pig.world
// We still need to some help in Fund, Tech.
contract plasmaToken {
  function addBalance(address player,uint256 amount) public returns (bool success);
  function minusBalance(address player,uint256 amount) public returns (bool success);

}

contract PlasmaChainManager {

    bytes constant PersonalMessagePrefixBytes = "\x19Ethereum Signed Message:\n32";
    uint32 constant blockHeaderLength = 161;
    plasmaToken plasmatoken = plasmaToken(0xaae11d99435562380c29cb61ee05794d7e6b7a38);

    struct BlockHeader {
        uint256 blockNumber;
        bytes32 previousHash;
        bytes32 merkleRoot;
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint256 timeSubmitted;
    }

    struct DepositRecord {
        uint256 blockNumber;
        address depositor;
        uint256 amount;
        uint256 timeCreated;
    }

    struct WithdrawRecord {
        uint256 blockNumber;
        uint256 txIndex;
        uint256 oIndex;
        address who;
        address[] vote_permission;
        uint256 amount;
        // bool votingComplete;
        uint256 expiredTime;
        bool ischallenge;
        address whoChallenge;
        bool ispay;
        // bool challengeSuccess;
    }
    
    struct TransferTransaction {
        address form;
        address to;
        uint32 time;
        uint256 amount;
        uint256 nonce;
    }

    address public owner;
    uint256 public lastBlockNumber;
    
    mapping(address => bool) public verifier;
    
    mapping(uint256 => BlockHeader) public headers;
    
    mapping(address => DepositRecord[]) public depositRecords;
    mapping(bytes32 => WithdrawRecord) public withdrawRecords;
    
    mapping(bytes32 => TransferTransaction) public transactionRecords;
    
    mapping(address => uint256) public result;
    mapping(address => mapping(bytes32 => bool)) public iscount;


    function PlasmaChainManager() public {
        owner = msg.sender;
        lastBlockNumber = 0;
    }
    
    event ApplyVerifier(address applyer);
    
    function applyVerifier() payable public{
        // require(msg.value == 1 ether);
        require(!verifier[msg.sender]);
        
        verifier[msg.sender] = true;
        ApplyVerifier(msg.sender);
    }
    
    event DropOutVerifier(address applyer);
    
    function dropuutVerifier()  public{
        require(verifier[msg.sender]);
        
        verifier[msg.sender] = false;
        
        //pending 7 days to refund, but in testmode refund immediately
        msg.sender.transfer(1 ether);
        
        DropOutVerifier(msg.sender);
    }
    

    event HeaderSubmittedEvent(address signer, uint32 blockNumber);

    function submitBlockHeader(bytes header) public returns (bool success) {
        require(header.length == blockHeaderLength);
        require(verifier[msg.sender]);

        bytes32 blockNumber;
        bytes32 previousHash;
        bytes32 merkleRoot;
        bytes32 sigR;
        bytes32 sigS;
        bytes1 sigV;
        assembly {
            let data := add(header, 0x20)
            blockNumber := mload(data)
            previousHash := mload(add(data, 32))
            merkleRoot := mload(add(data, 64))
            sigR := mload(add(data, 96))
            sigS := mload(add(data, 128))
            sigV := mload(add(data, 160))
            if lt(sigV, 27) { sigV := add(sigV, 27) }
        }

        // Check the block number.
        require(uint8(blockNumber) == lastBlockNumber + 1);

        // Check the signature.
        bytes32 blockHash = keccak256(PersonalMessagePrefixBytes, keccak256(blockNumber,
            previousHash, merkleRoot));
        address signer = ecrecover(blockHash, uint8(sigV), sigR, sigS);
        require(msg.sender == signer);

        // Append the new header.
        BlockHeader memory newHeader = BlockHeader({
            blockNumber: uint8(blockNumber),
            previousHash: previousHash,
            merkleRoot: merkleRoot,
            r: sigR,
            s: sigS,
            v: uint8(sigV),
            timeSubmitted: now
        });
        headers[uint8(blockNumber)] = newHeader;

        // Increment the block number by 1 and reset the transaction counter.
        lastBlockNumber += 1;

        HeaderSubmittedEvent(signer, uint8(blockNumber));
        return true;
    }

    event DepositEvent(address from, uint256 amount,
        uint256 indexed blockNumber);

    function deposit(uint amount) payable public returns (bool success) {
        DepositRecord memory newDeposit = DepositRecord({
            blockNumber: lastBlockNumber,
            depositor: msg.sender,
            amount: msg.value,
            timeCreated: now
        });
        plasmatoken.minusBalance(msg.sender,amount);
        depositRecords[msg.sender].push(newDeposit);
        // DepositEvent(msg.sender, msg.value, newDeposit.blockNumber);
        DepositEvent(msg.sender, amount, newDeposit.blockNumber);
        return true;
    }

    event WithdrawalStartedEvent(bytes32 withdrawalId);

    function startWithdrawal(
        uint256 blockNumber,
        uint256 txIndex,
        uint256 oIndex,
        bytes targetTx,
        bytes proof
    )
        public payable
        returns (bytes32 withdrawalId)
    {
        address who;
       address to;
       bytes4 time;
       bytes8 amount;
   
       assembly {
           let data := add(targetTx, 0x20)
           who := mload(data)
           to := mload(add(data, 20))
           time := mload(add(data, 52))
           amount := mload(add(data, 56))
     
       }
       require(who == msg.sender);
      require(to == 0x0000000000000000000000000000000000000000); 
         bytes32 TransactionHash =  keccak256(who, to, uint(time), uint(amount));

        require(msg.value == 1 ether);
        BlockHeader memory header = headers[blockNumber];
        require(header.blockNumber > 0);
        require(isValidProof(header.merkleRoot, TransactionHash, proof));

        bytes32 withdrawalId_ = keccak256(msg.sender,amount,now); 
        WithdrawRecord storage record = withdrawRecords[withdrawalId_];
        require(record.expiredTime == 0);

        // Construct a new withdrawal.
        record.blockNumber = blockNumber;
        record.txIndex = txIndex;
        record.oIndex = oIndex;
        record.who = who;
        record.amount = uint(amount);
        // record.priority = priority;

        record.who = msg.sender;
        record.amount =  uint(amount);
        record.expiredTime = now + 10 minutes;
        WithdrawalStartedEvent(withdrawalId_);
        return withdrawalId_;
    }
    
    event WithdrawalPermissionEvent(uint256 withdrawalId);
    
    // function persmissionWithdrawal(
    //     bytes32 withdrawalId
    // )
    //     public
    //     returns (bool permission)
    // {
    //     require(verifier[msg.sender]);
    //     require(withdrawRecords[withdrawalId].vote_permission.length<1);
    //     // require(!withdrawRecords[withdrawalId].votingComplete);

    //     bool isnotadd = true;
    //     for(uint8 i =0;i<withdrawRecords[withdrawalId].vote_permission.length;i++){
    //         if(withdrawRecords[withdrawalId].vote_permission[i] == msg.sender) isnotadd = false;
    //     }
    //     if(isnotadd){
    //         withdrawRecords[withdrawalId].vote_permission.push(msg.sender);
    //         return true;
    //     } else
    //         return true;
    // }
    
    // function voteCompleteWithdrawal(bytes32 withdrawalId) public
    // {
    //     require(withdrawRecords[withdrawalId].vote_permission.length>=1);
    //     require(!withdrawRecords[withdrawalId].ispay);
    //     // require(!withdrawRecords[withdrawalId].votingComplete);
                
    //     uint8 verifierQualified = 0;
    //     for(uint8 i =0;i<withdrawRecords[withdrawalId].vote_permission.length;i++){
    //         if(verifier[withdrawRecords[withdrawalId].vote_permission[i]]) verifierQualified++;
    //     }
        
    //     if(verifierQualified >= 1){
    //         // withdrawRecords[withdrawalId].votingComplete = true;
    //         withdrawRecords[withdrawalId].expiredTime = now + 10 minutes;
    //     } 
    // }

    event WithdrawalChallengedEvent(uint256 withdrawalId);

    function challengeWithdrawal(
        bytes32 withdrawalId,
        uint256 blockNumber,
        uint256 txIndex,
        uint256 oIndex,
        bytes targetTx,
        bytes proof
        ) 
         public
         payable
        returns (bool success)
         {
            address who;
       address to;
       bytes4 time;
       bytes8 amount;
            assembly {
           let data := add(targetTx, 0x20)
           who := mload(data)
           to := mload(add(data, 20))
           time := mload(add(data, 52))
           amount := mload(add(data, 56))
     
       }
       
         bytes32 TransactionHash =  keccak256(who, to, uint(time), uint(amount));
        // require(msg.value == 1 ether);
        // require(withdrawRecords[withdrawalId].votingComplete);
        BlockHeader memory header = headers[blockNumber];
        require(!withdrawRecords[withdrawalId].ispay);
        require(blockNumber>withdrawRecords[withdrawalId].blockNumber);
        require(!withdrawRecords[withdrawalId].ischallenge);
        require(isValidProof(header.merkleRoot, TransactionHash, proof));
        WithdrawRecord storage record = withdrawRecords[withdrawalId];


        if (isWithdrawalSpent(targetTx, record)) {
             record.ischallenge = true;
            record.whoChallenge = msg.sender;
            record.ischallenge = true;
            record.ispay = true;
            msg.sender.transfer(1 ether);

            return true;
        }
    }
    
    
    
    function finalizeWithdrawal(bytes32 withdrawalId) public {
        require(!withdrawRecords[withdrawalId].ischallenge);
        require(!withdrawRecords[withdrawalId].ispay);
        require(withdrawRecords[withdrawalId].expiredTime < now);
        
        
            withdrawRecords[withdrawalId].ispay = true;
            withdrawRecords[withdrawalId].who.transfer(1 ether);
            plasmatoken.addBalance(withdrawRecords[withdrawalId].who,withdrawRecords[withdrawalId].amount);
       
    }
    
    // function proveTransaction_Transfer(uint256 blockNumber,uint256 nonce,bytes targetTx,bytes proof) public {
        
    //     BlockHeader memory header = headers[blockNumber];
    //     require(header.blockNumber > 0);
        
    //   address who;
    //   address to;
    //   bytes4 time;
    //   bytes8 amount;

       
    //   assembly {
    //       let data := add(targetTx, 0x20)
    //       who := mload(data)
    //       to := mload(add(data, 20))
    //       time := mload(add(data, 52))
    //       amount := mload(add(data, 56))
    //   }
       
    //   bytes32 TransactionHash =  keccak256(who, to, uint(time), uint(amount));
        
    // //   address signer = ecrecover(TransactionHash, uint8(sigV), sigR, sigS);
       
    // //   require(signer == who);
       
    //     // Check if the transaction is in the block.
    //     require(isValidProof(header.merkleRoot, TransactionHash, proof));
        
    //     transactionRecords[TransactionHash] = (TransferTransaction(who,to,uint32(time),uint(amount),nonce));
        
    //     //TO DO
    //     //count transaction result
    //     //if transaction be counted, add to iscount and result
    //     //prevent count twice
    // }

    event WithdrawalCompleteEvent(uint256 indexed blockNumber,
        uint256 exitBlockNumber, uint256 exitTxIndex, uint256 exitOIndex);


    function isValidProof(bytes32 root, bytes32 target, bytes proof)
        pure
        internal
        returns (bool valid)
    {
        bytes32 hash = target;
        for (uint i = 32; i < proof.length; i += 33) {
            bytes1 flag;
            bytes32 sibling;
            assembly {
                flag := mload(add(proof, i))
                sibling := mload(add(add(proof, i), 1))
            }
            if (flag == 0) {
                hash = keccak256(sibling, hash);
            } else if (flag == 1) {
                hash = keccak256(hash, sibling);
            }
        }
        return hash == root;
    }
    
        function isWithdrawalSpent(bytes targetTx, WithdrawRecord record)
        view
        internal
        returns (bool spent)
    {
         address who;
       address to;
       bytes4 time;
       bytes8 amount;

       
       assembly {
           let data := add(targetTx, 0x20)
           who := mload(data)
           to := mload(add(data, 20))
           time := mload(add(data, 52))
           amount := mload(add(data, 56))
       }
       require(who == record.who);

        // Check two inputs individually if it spent the given withdrawal.
       return true;
    }

}
