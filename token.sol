//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Manager/Member.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract Token is Initializable, ERC20Upgradeable, Member {
    string private constant _name = "MCA TOKEN";
    string private constant _symbol = "MCA";
    uint256 public MAX_MINT_MCA;

    uint256 public lastBlockSwap;
    uint256 public fromSwapAmount;
    uint256 public toSwapAmount;
    
    // check not from contract
    bool public cantContract;  
    mapping (address => bool) public whiteList;

    modifier onlyPool{
        require(msg.sender == address(manager.members("NFTStakePool")) || msg.sender == address(manager.members("nft")), "permission denied");
        _;
    }
    
    function batchAddToWhitelist(address[] memory _address) external {
        require(manager.members("owner") != address(0), "member owner empty");
        require(msg.sender == manager.members("owner"), "only owner");
        uint256 i;
        uint256 len = _address.length;
        for(i; i < len; i++) {
            whiteList[_address[i]] = true;
        }
    }
    
    function setCantContract(bool _cantContract) external {
        require(manager.members("owner") != address(0), "member owner empty");
        require(msg.sender == manager.members("owner"), "only owner");
        cantContract = _cantContract;
    }

    function initialize(uint256 _totalSupply) public initializer {
        __initializeMember();
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);

        MAX_MINT_MCA = 5000000 * 1e18;
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function mint(address to, uint256 amount) external onlyPool {
        require(MAX_MINT_MCA >= (totalSupply() + amount), "token totalSupply reach the upper limit");
        _mint(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        checkContractTransfer(from);
        checkContractTransfer(to);
        checkSwap(from, to, amount );
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        checkContractTransfer(msg.sender);
        checkContractTransfer(to);
        checkSwap(msg.sender, to, amount );
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function checkSwap(address from, address to, uint256 amount ) internal {
        if (manager.members("PancakeSwapPair") != address(0)) {
            address pair = manager.members("PancakeSwapPair");

            if((from == pair || to == pair) && lastBlockSwap != block.number) {
                lastBlockSwap = block.number;
                toSwapAmount = 0;
                fromSwapAmount = 0;
            }

            if (from == pair) {
                if(amount > fromSwapAmount) {
                    fromSwapAmount = amount;
                }

                if(toSwapAmount != 0){
                    checkDiff(toSwapAmount, fromSwapAmount);
                }
            }

            if (to == pair) {
                if(amount > toSwapAmount) {
                    toSwapAmount = amount;
                }

                if(fromSwapAmount != 0){
                    checkDiff(toSwapAmount, fromSwapAmount);
                }
            }
        }
        
    }

    function checkDiff(uint256 num1, uint256 num2) internal pure {
        if(num1 > num2){
            uint256 diff = num1-num2;
            require(diff > num2* 2 / 100, "Frequent operation, please try again later");
        } else {
            uint256 diff = num2-num1;
            require(diff > num1* 2 / 100, "Frequent operation, please try again later");
        }
    }
    function checkContractTransfer(address addr) internal view {
        if(isContract(addr)) {
            if(cantContract) {
                require(whiteList[addr], "can not contract transaction");
            }
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
