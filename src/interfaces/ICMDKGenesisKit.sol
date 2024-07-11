// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC7572} from "./IERC7572.sol";
import {IERC4906} from "./IERC4906.sol";

interface ICMDKGenesisKit is IERC7572, IERC4906 {
    function setBaseURI(string calldata baseURI_) external;

    function setERC721TransferExempt(address target_, bool state_) external;

    function setContractURI(string memory uri) external;
}
