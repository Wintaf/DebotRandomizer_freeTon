pragma ton-solidity >= 0.45.0;
pragma AbiHeader expire;

import "./IRandomizer.sol";


library Errors {
    uint constant IS_NOT_OWNER = 101;
    uint constant IS_EXT_MSG = 108;
    uint constant FEE_TOO_SMALL = 1001;
}

contract Randomizer is IRandomizer {

    mapping(address => Random[]) public history;


    modifier checkPayment {
        require(msg.sender != address(0), Errors.IS_EXT_MSG);
        require(msg.value > 400 milliton, Errors.FEE_TOO_SMALL);
        tvm.accept();
        _;
    }

    function returnChange() private pure inline {
        msg.sender.transfer(0, false, 64);
    }
    constructor() public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    function getRandom(uint lower, uint upper) public override checkPayment {
        uint rand = lower + rnd.next(upper - lower);
        history[msg.sender].push(Random(lower, upper, rand, "(number)"));
        returnChange();
    }

    function getRandomCoinFlip() public override checkPayment {
        uint8 rand = rnd.next(1);
        if (rand == 1) {
            history[msg.sender].push(Random(0, 0, 0, "Heads"));
        } else {
            history[msg.sender].push(Random(0, 0, 0, "Tails"));
        }
        returnChange();
    }

/*
    function getRandomCOINFLIP() public override checkPayment {
        uint rand = rnd.next(2);
        if (rand == 1) {
            history[msg.sender].randomCOINFLIP[].push(RandomCOINFLIP("heads"));
        } else {
            history[msg.sender].randomCOINFLIP[].push(RandomCOINFLIP("tails"));
        }
    }
*/

    function getLastOperation(address who) public view override returns(Random) {
        if(history[who].length > 0) {
            return history[who][history[who].length - 1];
        }
        Random empty;
        return empty;
    }

    /*
    function getRandomHistory(address who) public view override returns(Random[]) {
        return history[who];
    }
    */
}