// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*

  ___ __  __ ____ _  _     __   ___   __            
 / __|  \/  |  _ ( )/ )   /. | / _ \ /. |           
( (__ )    ( )(_) )  (   (_  _| (_) |_  _)          
 \___|_/\/\_|____(_)\_)_ __(_)_\___/ _(_)

                                                                                                                                                                                                                                         
Welcome to the Connected Music Development Kit - the next-generation digital music protocol, designed to harness the opportunities that exist within AI and Web3 for the global music industry ecosystem. These CMDK Genesis Kits will grant you inside access to eco-system pre-launch, attracting more access, utility and rewards as described in the documentation. Each 404 tokens is fractionally tradable on a DEX and each whole token converts into an NFT in your wallet. Tokens and NFTs will soon be bridgeable to other chains and will play a role in the validation and curation of the Connected Music Network.

At the time of contract deployment, the following links are official:

tg: https://t.me/DROPcmdkportal
web: https://dropcmdk.ai/
x: https://x.com/dropcmdk
github: https://github.com/dropcmdk
    
*/

import {ICMDKGenesisKit} from "./interfaces/ICMDKGenesisKit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404} from "erc404/contracts/ERC404.sol";

/**
 * @title CMDK Genesis Kit
 * @notice CMDK Genesis Kit begins with fungible tokens.
 * When a user has at least one base unit (10^18) amount of tokens, they will automatically receive an NFT.
 * NFTs are minted as an address accumulates each base unit amount of tokens.
 */
contract CMDKGenesisKit is ICMDKGenesisKit, Ownable, ERC404 {
    string private _baseURI;
    string private _contractURI;
    bool private _singleUri = true;

    constructor(address owner_) ERC404("CMDK Genesis Kit", "$CMK404", 18) Ownable(owner_) {
        // Do not mint the ERC721s to the initial owner, as it's a waste of gas.
        _setERC721TransferExempt(owner_, true);
        _mintERC20(owner_, 5_000 * units);
    }

    // External Functions

    /**
     * @dev Set the base URI.
     * @param baseURI_ The base URI to set.
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURI = baseURI_;
        emit BatchMetadataUpdate(1, 5_000);
    }

    /**
     * @dev Set address to skip NFT minting for
     * @param target_ Address to skip NFT minting for
     * @param state_ Skip state for address
     */
    function setERC721TransferExempt(address target_, bool state_) external onlyOwner {
        _setERC721TransferExempt(target_, state_);
    }

    /**
     * @dev Set the contract URI.
     * @param uri The contract URI to set.
     */
    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
        emit ContractURIUpdated();
    }

    /**
     * @dev Set the metadata to be the same for all tokens.
     * @param singleUri_ The contract URI to set.
     */
    function setSingleUri(bool singleUri_) external onlyOwner {
        _singleUri = singleUri_;
    }

    // Private functions

    // Public functions

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId The token ID to query.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_singleUri) {
            return _baseURI;
        }
        return string.concat(_baseURI, Strings.toString(tokenId));
    }

    /**
     * @dev Returns the metadata URI for the contract.
     * @return The uri to the contract metadata.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Internal functions
}
