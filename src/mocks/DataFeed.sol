// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IChainlinkDataFeed.sol";

contract mockOracle is AggregatorV3Interface {
    uint8 public decimals = 8;

    function description() external view returns (string memory) {
        return "";
    }

    function version() external view returns (uint256) {
        return 0;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 92233720368547793207;
        answer = 2896400000000;
        startedAt = 1683248147;
        updatedAt = 1683248147;
        answeredInRound = 92233720368547793207;
    }
}
