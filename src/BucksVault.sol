// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC20} from "solady/tokens/ERC20.sol";

import {BucksToken} from "./Bucks.sol";
import {AggregatorV3Interface} from "./IChainlinkDataFeed.sol";

contract BucksVault is ERC721 {
    BucksToken public immutable BUCKS;
    ERC20 public immutable WBTC;
    /// @dev Chainlink data feed for WBTC/USD.
    AggregatorV3Interface public immutable WBTC_DATAFEED;

    address public immutable TREASURY;

    uint256 public constant BPS = 100_00;
    uint256 public constant BPS_MAX_MINT = 80_00;
    uint256 public constant BPS_LIQUIDATE = 85_00;

    uint256 public totalSupply;

    mapping(uint256 vaultId => uint256 wbtcAmount) public vaultsValue;
    mapping(uint256 vaultId => uint256 debtAmount) public vaultsDebt;

    event Liquidate(uint256 vaultId, address origOwner, address liquidator, uint256 debtPayed);

    constructor(address _WBTC, address _chainlinkdatafeed) {
        TREASURY = msg.sender;
        BUCKS = new BucksToken();
        WBTC = ERC20(_WBTC);
        WBTC_DATAFEED = AggregatorV3Interface(_chainlinkdatafeed);
    }

    function createVault() external returns (uint256 newVaultId) {
        newVaultId = ++totalSupply;
        _mint(msg.sender, newVaultId);
    }

    function deposit(uint256 vaultId, uint256 amount) external {
        _exists(vaultId);
        WBTC.transferFrom(msg.sender, address(this), amount);

        vaultsValue[vaultId] += amount;
    }

    function widthdraw(uint256 vaultId, uint256 amount) external {
        require(_ownerOf(vaultId) == msg.sender, "!not vault owner");
        require(amount > 0, "amount must be greater than 0");
        require(maxMint(vaultId) > 0, "Please repay debt first");
        
        vaultsValue[vaultId] -= amount;

        if (vaultsDebt[vaultId] > 0) {
            require(maxMint(vaultId) > 0, "Please repay debt first");
        }

        WBTC.transfer(msg.sender, amount);
    }

    /// @notice Mint debt for a vault
    /// @dev Explain to a developer any extra details
    /// @param vaultId The id of the vault
    /// @param amount The amount of debt to mint
    function mintDebt(uint256 vaultId, uint256 amount) external {
        require(_ownerOf(vaultId) == msg.sender, "!not vault owner");
        require(amount > 0, "amount must be greater than 0");
        require(amount <= maxMint(vaultId), "cant mint that much");

        vaultsDebt[vaultId] += amount;
        BUCKS.mint(msg.sender, amount);
    }

    function liquidate(uint256 vaultId) external {
        require(_exists(vaultId), "!vault not exist");
        uint256 debt = vaultsDebt[vaultId];
        uint256 vaultValue = vaultCollateralValue(vaultId);
        require(debt * BPS / vaultValue > 85_00, "not liquidatable");

        BUCKS.burn(msg.sender, debt);
        BUCKS.transferFrom(msg.sender, TREASURY, debt / 100);
        vaultsDebt[vaultId] = 0;
        address origOwner = _ownerOf(vaultId);
        _transfer(origOwner, msg.sender, vaultId);

        emit Liquidate(vaultId, origOwner, msg.sender, debt);
    }

    // return USD in 1e18 decimal format
    function vaultCollateralValue(uint256 vaultId) public view returns(uint256) {
        require(_exists(vaultId), "!vault not exist");

        return vaultsValue[vaultId] * WBTC_PRICE() * 100;
    }
    
    function maxMint(uint256 vaultId) public view returns (uint256) {
        uint256 maxMintAmount = vaultCollateralValue(vaultId) * BPS_MAX_MINT / BPS;
        
        uint256 bedt = vaultsDebt[vaultId];
        if (bedt > maxMintAmount) {
            return 0;
        } else {
            return maxMintAmount - bedt;
        }
    }

    /// @notice price of WBTC in USD with 9 decimal places
    function WBTC_PRICE() public view returns (uint256 maxMintAmount) {
        (, int256 price, , , ) = WBTC_DATAFEED.latestRoundData();
        return uint256(price);
    }

    

    function name() public pure override returns (string memory) {
        return "BucksVault";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "BV";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view override returns (string memory) {}
}
