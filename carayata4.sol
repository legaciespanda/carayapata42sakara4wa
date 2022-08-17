// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SchrowRecatored is Ownable, ReentrancyGuard{


    enum EscrowStatus { OFFERED, AWAITING_DELIVERY, COMPLETED}
    bool public paused;
    bytes32 private _ernest;
    //0x20b8B0aB5283195110e6d536b31532cb98fCe805
    
    //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

    ////////////////////////////////EVENTS//////////////////////
    

    //CONSTRUCTOR
    constructor(string memory _setErnest) {
         _ernest = keccak256(abi.encodePacked(_setErnest));
    }

    // Pause & Unpause escrow contract
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    // Read ernest
    function getErnest() public view onlyOwner isPaused returns (bytes32){
        return _ernest;
    }

    // Write a new ernest
    function setSecret(string memory _newernest, string memory _oldernest) public onlyOwner isPaused {
        require(keccak256(abi.encodePacked(_oldernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        _ernest = keccak256(abi.encodePacked(_newernest));
    }

    function hash(
        string memory _text
    ) public  returns (bytes32) {
        _ernest = keccak256(abi.encodePacked(_text));
        return keccak256(abi.encodePacked(_text));
    }

    //compare ernest
    function checkSecretKey(string memory _existingSecret) public view onlyOwner returns (bool){
        
        if(keccak256(abi.encodePacked(_existingSecret)) ==  _ernest){
            return true;
        }
        return false;
    }

    ///////MAPPING////////////////////////////////////
         mapping (string => Item) private Items;
    /////////////////////////////////////////////////


    ////MODIFIERS//////////////////////////////////////
    //Buyer modifier
        modifier onlyBuyer(string memory _paymentPhrase){
            require(msg.sender == Items[_paymentPhrase].buyerAddress,
            "Crypto Eskrow: caller is not the BUYER");
            _;
        }

        modifier onlySeller(string memory _paymentPhrase){
            require(msg.sender == Items[_paymentPhrase].sellerAddress,
            "Crypto Eskrow: caller is not the SELLER");
            _;
        }

        modifier isPaused(){
            require(paused == false, "Crypto Eskrow: Operation forbidden. Check back");
            _;
        }

        modifier onlySellerOrBuyer(string memory _paymentPhrase){
            require(msg.sender == Items[_paymentPhrase].sellerAddress || msg.sender == Items[_paymentPhrase].buyerAddress,
            "Crypto Eskrow: caller is neither the SELLER or BUYER");
            _;
        }

        //checks if item exist in the blockchain
        modifier itemExist(string memory _paymentPhrase){
            require(Items[_paymentPhrase].exists, "Crypto Eskrow: Escrow Item does not exist");
            _;
        }
    ///////////////////////////////////////////////////

    //data structures///////////////////////////////////
    struct Item {
        address buyerAddress;
        address sellerAddress;
        string price;
        string paymentPhrase;
        string itemDescription;
        bool exists;
        EscrowStatus status;
        bool lock;
    }
    ////////////////////////////////////////////////////


    ///////ESCROW LOGIC////////////////////////////////
    //payable chargeFee
    //@dev: Buyer initiates/start an escrow contract
    //funds is deposited into the smart contract
    //@param: takes in sellers address, payment phrase, and description
    // function startContract(address _sellerAddress, string memory _price, string memory _paymentPhrase, string memory desc) external payable  isPaused{
    //     //buyer cannot initiate a contract with himself or his own address
    //     require(msg.sender != _sellerAddress, "Crypto Eskrow: You can't create an escrow contract with your address");
    //     require(msg.sender != address(0));

    //     Item memory buyer_data = Item(
    //         msg.sender,
    //         _sellerAddress,
    //         _price,
    //         _paymentPhrase,
    //         desc,
    //         true,
    //         EscrowStatus.AWAITING_DELIVERY,
    //         false
    //     );

    //     //Items[msg.sender] = buyer_data;
    //     Items[_paymentPhrase] = buyer_data;
    //     //buyerEther
    //     //transfer fund to smart contract
    //     //payable(address(this)).transfer(_price);

    // }

    function startContract(address _sellerAddress, string memory _price, string memory _paymentPhrase, string memory desc, string memory ernest) external payable  isPaused{
        //buyer cannot initiate a contract with himself or his own address
        require(msg.sender != _sellerAddress, "Crypto Eskrow: You can't create an escrow contract with your address");
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        require(msg.sender != address(0));

            Item memory buyer_data = Item(
                msg.sender,
                _sellerAddress,
                _price,
                _paymentPhrase,
                desc,
                true,
                EscrowStatus.AWAITING_DELIVERY,
                false
            );

            //Items[msg.sender] = buyer_data;
            Items[_paymentPhrase] = buyer_data;
            //buyerEther
            //transfer fund to smart contract
            //payable(address(this)).transfer(_price);

    }
    //@dev: Seller can withdraw his funds sent to the smart contract by the buyer
    //checks to see if item exist in blockchain
    //only the seller can withdraw funds sent by the buyer
    //after succesful withdrawal, escrow contract is deleted from the blockchain, hence contract completed
    //@param: takes in payment phrase
     function endContract(string memory _paymentPhrase, uint256 _price, string memory ernest) public itemExist(_paymentPhrase) isPaused{
         require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
         require(Items[_paymentPhrase].lock == false, "Crypto Eskrow: You can't revoke this escrow contract. It has been locked");
         require(msg.sender == Items[_paymentPhrase].sellerAddress, "Crypto Eskrow: caller is not the SELLER");

            //pay the seller
            payable(msg.sender).transfer(_price);

            //delete the contract from blockchain
            delete Items[_paymentPhrase];
     }

    //@dev: Buyer did not receive the item, revokes the contract with the seller and gets his funds back
    //@param: takes in payment phrase
     function revokeContract(string memory _paymentPhrase, uint256 _price, string memory ernest) public itemExist(_paymentPhrase) onlyBuyer(_paymentPhrase) isPaused{
         require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
         require(Items[_paymentPhrase].lock == false, "Crypto Eskrow: You can't revoke this escrow contract. It has been locked");

              payable(msg.sender).transfer(_price);

              delete Items[_paymentPhrase];

     }

     function lockDeal(string memory _paymentPhrase, string memory ernest)public itemExist(_paymentPhrase) onlySeller(_paymentPhrase) isPaused{
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
         Items[_paymentPhrase].lock = true;
     }

    function unlockDeal(string memory _paymentPhrase, string memory ernest)public itemExist(_paymentPhrase) onlySeller(_paymentPhrase) isPaused{
         require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
         Items[_paymentPhrase].lock = false;
     }


    //////////////////////////////////////////////////

    //@dev:Gets eschrow data
    //@param: takes in payment phrase
    function getEscrowData(string memory _paymentPhrase) public view itemExist(_paymentPhrase) isPaused returns(address, address, string memory, string memory, bool, EscrowStatus, bool) {

        return (
             Items[_paymentPhrase].buyerAddress,
             Items[_paymentPhrase].sellerAddress,
             Items[_paymentPhrase].price,
             Items[_paymentPhrase].itemDescription,
             Items[_paymentPhrase].exists,
             Items[_paymentPhrase].status,
             Items[_paymentPhrase].lock
        );
    }

    //get amount based on payment phrase
    function getAmountByPhrase(string memory _paymentPhrase, string memory ernest) public view isPaused returns(string memory){
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        return Items[_paymentPhrase].price;
    }

    //get the status of the escrow
    function isEscrowLocked(string memory _paymentPhrase, string memory ernest) public view isPaused returns(bool){
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        return Items[_paymentPhrase].lock;
    }


    // Withdraw ETH
    function withdraw(uint256 _amount, string memory ernest) public onlyOwner isPaused {
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        require(address(this).balance > 0, "Crypto Eskrow: There is no cash on the contract to withdraw");
        //payable(msg.sender).transfer(address(this).balance);
        payable(msg.sender).transfer(_amount);
        // (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        // require(sent, "Failure to send Ether");
    }
     
    //echecks balance of smart contract
    function checkBalance(string memory ernest) public view onlyOwner isPaused returns(uint) {
        require(keccak256(abi.encodePacked(ernest)) ==  _ernest, "Crypto Eskrow: Your are not authorize to perform this operation. Contact Crypto Escrow hello@cryptoescrow.io");
        return address(this).balance; //1000000000000000000 wei
        //80000000000000000
    }

    //function to receive Ether, msg.data must be empty
    receive() external payable {}

    //fallback function is called when msg.data is not empty
    //fallback() external payable{}

}
