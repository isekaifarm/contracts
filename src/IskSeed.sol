// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract IskSeed is Ownable, Pausable, ERC20, ERC20Burnable {
    using ECDSA for bytes32;

    struct SeedType {
        uint256 cost;
        bool exists;
    }

    struct ProductType {
        uint256 price;
        bool exists;
    }

    mapping(uint256 => SeedType) public seedTypes;
    mapping(uint256 => ProductType) public productTypes;
    mapping(bytes32 => bool) private isUsed;

    IERC20 public iskToken;
    address private signerAddress;

    constructor(
        address _initialOwner,
        address _iskToken,
        address _signerAddress
    ) Ownable(_initialOwner) ERC20("IsekaiFarmSeed", "ISKS") {
        iskToken = IERC20(_iskToken);
        signerAddress = _signerAddress;

        // 6 types of seed and cost
        seedTypes[0] = SeedType(10, true);
        seedTypes[1] = SeedType(15, true);
        seedTypes[2] = SeedType(20, true);
        seedTypes[3] = SeedType(25, true);
        seedTypes[4] = SeedType(30, true);
        seedTypes[5] = SeedType(35, true);

        // 6 types of seed and price
        productTypes[0] = ProductType(11, true);
        productTypes[1] = ProductType(16, true);
        productTypes[2] = ProductType(21, true);
        productTypes[3] = ProductType(26, true);
        productTypes[4] = ProductType(31, true);
        productTypes[5] = ProductType(36, true);
    }

    uint256 public mintCost = 0.000001 ether;

    event TokensMinted(address indexed to, uint256 amount, uint256 seedType);
    event SeedTypeAdded(uint256 seedType, uint256 cost);
    event SeedTypeUpdated(uint256 seedType, uint256 newCost);
    event ProductSold(
        address indexed buyer,
        uint256 productType,
        uint256 amount
    );

    function mint(uint256 _seedType, uint256 _amount) public {
        require(seedTypes[_seedType].exists, "Seed type does not exist");
        uint256 totalMintCost = seedTypes[_seedType].cost * _amount;
        require(
            iskToken.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient ISK allowance"
        );

        iskToken.transferFrom(msg.sender, address(this), totalMintCost);

        _mint(msg.sender, _amount);

        emit TokensMinted(msg.sender, _amount, _seedType);
    }

    function sellProduct(
        string calldata _timestamp,
        bytes calldata _signature,
        uint256 _amount,
        uint256 _productType
    ) external {
        bytes32 message = getMessage(
            _timestamp,
            _amount,
            address(this),
            msg.sender
        );
        require(!isUsed[message], "Invalid signature, already used");
        require(_amount > 0, "Invalid amount");
        require(isValidData(message, _signature), "Invalid signature");
        require(
            productTypes[_productType].exists,
            "Product type does not exist"
        );
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");

        _burn(msg.sender, _amount);
        isUsed[message] = true;

        uint256 totalPrice = productTypes[_productType].price * _amount;
        iskToken.transfer(msg.sender, totalPrice);

        emit ProductSold(msg.sender, _productType, _amount);
    }

    function ownerMint(
        address _recipient,
        uint256 _amount,
        uint256 _seedType
    ) external onlyOwner {
        require(seedTypes[_seedType].exists, "Seed type does not exist");
        _mint(_recipient, _amount);
        emit TokensMinted(_recipient, _amount, _seedType);
    }

    function addSeedType(uint256 _seedType, uint256 _cost) external onlyOwner {
        require(!seedTypes[_seedType].exists, "Seed type already exists");
        seedTypes[_seedType] = SeedType(_cost, true);
        emit SeedTypeAdded(_seedType, _cost);
    }

    function updateMintCost(
        uint256 _seedType,
        uint256 newMintCost
    ) external onlyOwner {
        require(seedTypes[_seedType].exists, "Seed type does not exist");
        seedTypes[_seedType].cost = newMintCost;
        emit SeedTypeUpdated(_seedType, newMintCost);
    }

    function setiskToken(address _iskToken) external onlyOwner {
        iskToken = ERC20(_iskToken);
    }

    function getMessage(
        string calldata timestamp_,
        uint256 amount_,
        address contractAddress_,
        address msgSender_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(timestamp_, amount_, contractAddress_, msgSender_)
            );
    }

    function isValidData(
        bytes32 message_,
        bytes memory signature_
    ) public view returns (bool) {
        return message_.recover(signature_) == signerAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function collectEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function decimals() public pure override returns (uint8) {
        return 1;
    }
}
