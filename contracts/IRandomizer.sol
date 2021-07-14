pragma ton-solidity >= 0.45.0;
pragma AbiHeader expire;

struct Random {
    uint lower;
    uint upper;
    uint resultOfRand;
    string resultOfCoin;
}


interface IRandomizer {

    function getRandom(uint lower, uint upper) external;

    function getRandomCoinFlip() external;

    function getLastOperation(address who) external view returns(Random);
    //function getRandomHistory(address who) external view returns(Random[]);
}