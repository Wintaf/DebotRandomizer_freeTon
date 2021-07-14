pragma ton-solidity >= 0.45;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../lib/debot/Debot.sol";
import "../lib/debot/Terminal.sol";
import "../lib/debot/AddressInput.sol";
import "../lib/debot/NumberInput.sol";
import "../lib/debot/SigningBoxInput.sol";
import "../lib/debot/Menu.sol";

import "./IPayloadSender.sol";
import "./IRandomizer.sol";

contract RandomizerDebot is Debot {
    address _addrRandomizer;
    address _addrMultisig;
    uint32 _keyHandle;
    uint32 _idOperation; 

    constructor(address addrRandomizer) public {
        tvm.accept();
        _addrRandomizer = addrRandomizer;
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Randomizer Debot";
        version = "0.0.2";
        publisher = "@wintaf (telegram)";
        key = "";
        author = "wintaf";
        support = address.makeAddrStd(0, 0x0);
        hello = "Hello! I`m Debot that can randomize you any number!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [
            AddressInput.ID,
            NumberInput.ID,
            SigningBoxInput.ID,
            Menu.ID,
            Terminal.ID
        ];
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        mainMenu(0);
    }


    // point of enter in program
    function start() public override {
        mainMenu(0);
    }

    // upper and lower of random
    uint upper;
    uint lower;
    // result out of randomizer
    uint resultOfRand;

    function mainMenu(uint32 index) public {
        index;

        if(_addrMultisig == address(0)) {
            Terminal.print(0, 'In order to create Event you need to attach Multisig');
            attachMultisig();
            return;
        }

        uint32 idSetOperation = tvm.functionId(setOperation);

        MenuItem[] items;
        items.push(MenuItem("Randomize number", "", idSetOperation));
        items.push(MenuItem("Flip a coin", "", idSetOperation));
        //items.push(MenuItem("Check your last operation", "", idSetOperation));
        Menu.select("==What to do?==", "", items);
    }

    //these three are always the same(except address in function send)
    function attachMultisig() public {
        AddressInput.get(tvm.functionId(saveMultisig), "Enter Multisig address");
    }
    function saveMultisig(address value) public {
        _addrMultisig = value;
        mainMenu(0);
    }
    function setKeyHandle(uint32 handle) public {
        Terminal.print(0, format("msig {}", handle));
        _keyHandle = handle;
        CheckSignHandle();
    }
    function send(TvmCell payload) public view {
        optional(uint256) none;
        IPayloadSender(_addrMultisig).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(result),
            onErrorId: tvm.functionId(onError),
            signBoxHandle: _keyHandle
        } (
            _addrRandomizer,
            0.7 ton,
            false,
            3,
            payload
        );
    }
    
    
    function setOperation(uint32 index) public {
        Terminal.print(0, format("Chosen: {}", index));
        if ( index == 0 ) {
            _idOperation = tvm.functionId(getRandom);
            NumberInput.get(tvm.functionId(setUpper), "choice ur upper number", 0, 1000000000);
            
        } 
        else if ( index == 1 ) {
            _idOperation = tvm.functionId(getRandomCoinFlip);
            CheckSignHandle();
            
            
        }
        
    }

    function setUpper(uint value) public {
        upper = value;
        NumberInput.get(tvm.functionId(setLower), "choice ur lower number", 0, int256(upper));
    }
    function setLower(uint value) public {
        lower = value;
        CheckSignHandle();
    }
    function CheckSignHandle() public {
        if (_keyHandle == 0) {
            uint[] none;
            SigningBoxInput.get(tvm.functionId(setKeyHandle), "", none);
            return;
        }

        Terminal.print(_idOperation, format("({},{})", lower, upper));
    }
    function getRandom() public view {
        TvmCell payload = tvm.encodeBody(IRandomizer.getRandom, lower, upper);
        send(payload);
    }
    function getRandomCoinFlip() public view {
        TvmCell payload = tvm.encodeBody(IRandomizer.getRandomCoinFlip);
        
        send(payload);
    }

/*
    function getLastOperation() public view {
        IRandomizer(_addrRandomizer).getLastOperation{
            abiVer: 2,
            extMsg: true,
            callbackId: tvm.functionId(printResult),
            onErrorId: 0,
            time: 0,
            expire: 0,
            sign: false
        }(_addrMultisig);
    }
*/
    function result() public view {
        IRandomizer(_addrRandomizer).getLastOperation{
            abiVer: 2,
            extMsg: true,
            callbackId: tvm.functionId(printResult),
            onErrorId: 0,
            time: 0,
            expire: 0,
            sign: false
        }(_addrMultisig);
    }

    function printResult(Random res) public {
        Terminal.print(0, format("lower: {}, upper: {}, resultOfNum = {} resultOfCoin = {}",
            res.lower,
            res.upper,
            res.resultOfRand,
            res.resultOfCoin
        ));
        mainMenu(0);
    }
}