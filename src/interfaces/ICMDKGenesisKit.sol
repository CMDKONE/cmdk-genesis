// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICMDKGenesisKit {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function setBaseURI(string calldata baseURI_) external;

    function setSkipNFTForAddress(
        address skipAddress,
        bool skipNFT
    ) external returns (bool);

    function withdraw() external;

    function transfer(address to, uint256 amount) external returns (bool);
}
