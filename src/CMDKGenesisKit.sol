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

import "dn404/DN404.sol";
import "dn404/DN404Mirror.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC7572} from "./interfaces/IERC7572.sol";
import {IERC4906} from "./interfaces/IERC4906.sol";
import {ICMDKGenesisKit} from "./interfaces/ICMDKGenesisKit.sol";

/**
 * @title CMDK Genesis Kit
 * @notice CMDK Genesis Kit begins with fungible tokens.
 * When a user has at least one base unit (10^18) amount of tokens, they will automatically receive an NFT.
 * NFTs are minted as an address accumulates each base unit amount of tokens.
 */
contract CMDKGenesisKit is DN404, Ownable, IERC7572, IERC4906 {
    string private _baseURI;
    string private _contractURI;
    bool private _singleUri = true;

    constructor() {
        _initializeOwner(msg.sender);
        uint96 initialTokenSupply = (5_000) * 10 ** 18;
        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, msg.sender, mirror);
        _contractURI = "ipfs://QmZgzS1kd7gBsp7tzGtV9bvEJe93bHGFqnDfjXsPdLWfks";
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
     * @param skipAddress Address to skip NFT minting for
     * @param skipNFT Skip state for address
     */
    function setSkipNFTForAddress(address skipAddress, bool skipNFT) external onlyOwner returns (bool) {
        _setSkipNFT(skipAddress, skipNFT);
        return true;
    }

    /// @inheritdoc IERC7572
    function contractURI() external view returns (string memory) {
        return _contractURI;
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

    /**
     * @dev Returns the URI for a given token ID.
     * @param tokenId The token ID to query.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory result) {
        return _tokenURI(tokenId);
    }

    // Private functions

    // Public functions

    /// @inheritdoc DN404
    function name() public pure override returns (string memory) {
        return "CMDK Genesis Kit";
    }

    /// @inheritdoc DN404
    function symbol() public pure override returns (string memory) {
        return "$CMK404";
    }

    /// @dev Withdraw all ETH from the contract.
    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    // Internal functions

    /// @inheritdoc DN404
    function _tokenURI(uint256 tokenId) internal view override returns (string memory result) {
        if (_singleUri) {
            return _baseURI;
        }
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
        }
    }
}
