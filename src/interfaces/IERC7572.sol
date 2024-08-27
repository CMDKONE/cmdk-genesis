// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC7572 {
    /**
     * @dev Returns the metadata URI for the contract.
     * @return The uri to the contract metadata.
     */
    function contractURI() external view returns (string memory);

    event ContractURIUpdated();
}
