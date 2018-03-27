/*
   Oraclize random-datasource

   This contract uses the random-datasource to securely Pig.World Project Random Seed Source
*/

pragma solidity ^0.4.18;

import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
// contract ERC20Interface {
//     function transfer(address to, uint tokens) public returns (bool success);
// }


contract GameHouse {
    function call_back_random(string random) public {}
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
// contract Owned {
//     address public owner;
//     address public newOwner;

//     event OwnershipTransferred(address indexed _from, address indexed _to);

//     function Owned() public {
//         owner = msg.sender;
//     }

//     modifier onlyOwner {
//         require(msg.sender == owner);
//         _;
//     }

//     function transferOwnership(address _newOwner) public onlyOwner {
//         newOwner = _newOwner;
//     }
//     function acceptOwnership() public {
//         require(msg.sender == newOwner);
//         OwnershipTransferred(owner, newOwner);
//         owner = newOwner;
//         newOwner = address(0);
//     }
// }

contract RandomCenter is usingOraclize {
    address public Owner;
    event newRandomEvent(string,address,bytes32);


    mapping (bytes32 => address) public recordQuerIdFromAddress;
    

    function RandomCenter() {
        oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        // let's ask for N random bytes immediately when the contract is created!
    }
    
    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string _result, bytes _proof)public
    { 
        require(msg.sender == oraclize_cbAddress());
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..

            GameHouse gamehouse = GameHouse(recordQuerIdFromAddress[_queryId]);
            gamehouse.call_back_random(_result);
            
            newRandomEvent(_result,recordQuerIdFromAddress[_queryId],_queryId);
        }
    }
    
    function callNewRandom() public payable {
        uint N = 5; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 400000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); 
        recordQuerIdFromAddress[queryId] = msg.sender;
    }
    
    function() payable {

    }

    // // ------------------------------------------------------------------------
    // // Owner can transfer out any accidentally sent ERC20 tokens
    // // ------------------------------------------------------------------------
    // function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    //     return ERC20Interface(tokenAddress).transfer(owner, tokens);
    // }
    
    
    // // ------------------------------------------------------------------------
    // // Owner can transfer out any accidentally sent Ether
    // // ------------------------------------------------------------------------
    // function transferEther() public onlyOwner returns (bool success) {
    //     return owner.send(this.balance);
    // }
    
}
   