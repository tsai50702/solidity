pragma solidity ^0.4.16;

contract RandomCenter {
    function callNewRandom() public payable {}
}

contract MainContract {
    function payToPlay(address paidAddress,uint price) public {}
    function winTheGame(address winAddress,uint reward) public {}
    function balanceOf(address tokenOwner) public constant returns (uint) {}
}

contract Bingobingo {
    
    struct ticket{
        bytes5 numbers;
        uint24 round;
        bool ischarge;
    }
   
    mapping (address => mapping (uint24 => ticket)) public round_ticket;
    mapping (uint24 => bytes6) public win_number;
    mapping (uint24 => string) public random_string;
    mapping (uint24 => uint) public random_string_block_number;

    
    address public Owner;
   
    function Bingobingo () public {
        Owner = msg.sender;
    }

    uint24 public round = 0;
    uint24 public ticket_number = 0;
    uint256 public ticket_price = 1000000000000;
    uint256 public ticket_onwer = 500000000000;
    uint256 public ticket_prize = 500000000000;
    uint[] array;
    uint256 public prize_pool = 0;

    MainContract maincontract = MainContract(0x6fa9c53444a085098367d468b1751b6317023546);
   

    event ticket_history(bytes5 number,uint24 time,address addr,uint24 round,bytes32 hashedMessage,bytes32 prefixedHash,bool a);
    event one_number_history(bytes6);

    function sendticket(bytes5[] numbers,uint24[] times,address[] addrs, bytes32[] hashs, uint8[] vs, bytes32[] rs, bytes32[] ss) public {
       
       uint256 ticket_pricea = ticket_price;
       
       for(uint16 index=0;index<numbers.length;index++){
           
           bytes memory prefix = "\x19Ethereum Signed Message:\n32";
           bytes32 prefixedHash = keccak256(prefix, hashs[index]);
           bytes32 hashedMessage = keccak256(numbers[index],addrs[index],times[index]);
           
           bool a = (ecrecover(prefixedHash, vs[index], rs[index], ss[index]) == addrs[index] && 
           hashs[index] == hashedMessage && 
           getPlayerBalance(addrs[index])>=ticket_pricea);
        //   balanceOf[addrs[index]]>=ticket_pricea);
        
           if(a) {       
               bool b = round_ticket[addrs[index]][times[index]].round == 0;
               if(true){
                   ticket_number++;
                   minus_balance(addrs[index],ticket_pricea);
                //   balanceOf[addrs[index]] -= ticket_pricea;
                   round_ticket[addrs[index]][times[index]] = ticket(numbers[index],round,false);
                   ticket_history(numbers[index],times[index],addrs[index],round,hashedMessage,prefixedHash,a);
                   
               }
                   
           }
          
       }
   }
   
   
   function creat6number() public {
       require(msg.sender == Owner);
       
       array = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59];
       
       
        //依據本期總總金額結算：莊家收入、彩票池收入
        plus_balance(Owner, ticket_onwer * ticket_number);
        prize_pool += ticket_prize * ticket_number;
        ticket_number = 0;
       
       
        bytes6 number_ ;
       
        number_ |= bytes6(random_number(0,36) & 0xFF);
        number_ |= bytes6(random_number(1,35) & 0xFF) >> (8);
        number_ |= bytes6(random_number(2,34) & 0xFF) >> (16);
        number_ |= bytes6(random_number(3,33) & 0xFF) >> (24);
        number_ |= bytes6(random_number(4,32) & 0xFF) >> (32);
        number_ |= bytes6(random_number(5,31) & 0xFF) >> (40);

        win_number[round] = number_;
        round++;
   }
   
   function random_number(uint seed,uint modnum) private returns (byte) {
        byte char;
        uint anum=(uint(keccak256(block.blockhash(random_string_block_number[round]-seed), random_string[round] ))%modnum)+1;
        uint bnum = array[anum];
        char = byte(bnum);
        remove(anum);
        return char;
    }
    
    function check_your_number(address[] addrs,uint24[] times) public {
        for(uint16 index=0;index<addrs.length;index++){
            if(!round_ticket[addrs[index]][times[index]].ischarge){
                bytes6 number_ = round_ticket[addrs[index]][times[index]].numbers;
                bytes6 win_number_ = win_number[round_ticket[addrs[index]][times[index]].round];
                
                uint8 actual_win_num = 0;
                uint8 actual_repeat_num = 0;
                for(uint8 i=0;i<5;i++){
                    for(uint8 j=0;j<5;j++){
                        if(number_[j] == number_[i]){
                            actual_repeat_num++;
                        }
                        if(win_number_[i]==number_[j]){
                            actual_win_num++;
                        }
                    }
        
                }
                
                //判斷是否重複投注 (TO DO 判斷是否會ＧＧ)
                if(actual_repeat_num != 6){
                    actual_win_num = 0;
                }
                
                //領獎囉

                if(actual_win_num == 2 ){
                    plus_balance(addrs[index],2500);
                }
                if(actual_win_num == 3){
                    plus_balance(addrs[index],22000);
                }
                if(actual_win_num == 4){
                    plus_balance(addrs[index],250000);
                }
                if(actual_win_num == 5){
                    plus_balance(addrs[index],3500000);
                }
                
                round_ticket[addrs[index]][times[index]].ischarge = true;
            }
        }
    }
    
    function remove(uint index) public{
        if (index >= array.length) return;
        uint number;
        number=array[index];
        for (uint i = index; i<array.length-1; i++){
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        array.length--;
    }
   
        
    function getPlayerBalance(address _player) public constant returns (uint){
        return maincontract.balanceOf(_player);
    }
        
  function minus_balance(address player,uint token) private {
    maincontract.payToPlay(player,token);
  }
  
  function plus_balance(address player,uint token) private {
    maincontract.winTheGame(player,token);
  }
  
  function callNewRandom() public payable{
      RandomCenter r = RandomCenter(0x0295acf99ef2cf3a989e41a1c76fc754354fdaaa);
    r.callNewRandom();
  }
  
  function call_back_random(string random) public {
      require(msg.sender == 0x0295acf99ef2cf3a989e41a1c76fc754354fdaaa);
      if(random_string_block_number[round] == 0) {
          random_string[round] = random;
          random_string_block_number[round] = block.number;
      }
          
  }

    
}
