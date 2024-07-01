// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC7572} from "./IERC7572.sol";

interface ICMDKGenesisKit is IERC7572 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function setBaseURI(string calldata baseURI_) external;

    function setSkipNFTForAddress(address skipAddress, bool skipNFT) external returns (bool);

    function withdraw() external;

    function transfer(address to, uint256 amount) external returns (bool);

    function setContractURI(string memory uri) external;
}
