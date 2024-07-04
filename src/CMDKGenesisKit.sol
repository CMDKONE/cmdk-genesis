// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*

        ██████╗███╗   ███╗██████╗ ██╗  ██╗                       
        ██╔════╝████╗ ████║██╔══██╗██║ ██╔╝                       
        ██║     ██╔████╔██║██║  ██║█████╔╝                        
        ██║     ██║╚██╔╝██║██║  ██║██╔═██╗                        
        ╚██████╗██║ ╚═╝ ██║██████╔╝██║  ██╗                       
        ╚═════╝╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝                       
                                                                
        ██████╗ ███████╗███╗   ██╗███████╗███████╗██╗███████╗    
        ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔════╝██║██╔════╝    
        ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ███████╗██║███████╗    
        ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ╚════██║██║╚════██║    
        ╚██████╔╝███████╗██║ ╚████║███████╗███████║██║███████║    
        ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚══════╝    
                                                                
        ██╗  ██╗██╗████████╗                                      
        ██║ ██╔╝██║╚══██╔══╝                                      
        █████╔╝ ██║   ██║                                         
        ██╔═██╗ ██║   ██║                                         
        ██║  ██╗██║   ██║                                         
        ╚═╝  ╚═╝╚═╝   ╚═╝                                         

    DROPcmdk is the next-generation digital music protocol, designed to harness the opportunities 
    that exist within AI and Web3 in the global music industry ecosystem. The Connected Music Protocol 
    is designed to be music industry-compliant, but aggressively forward-thinking so anyone can launch 
    a Web3 Connected Music Store and turn followers into superfans.

    web: https://www.dropcmdk.ai/
    x: https://x.com/dropcmdk
    github: https://github.com/dropcmdk
    tg: https://t.me/DROPcmdkportal

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
    address public bridgeAddress;
    bool private _singleUri = true;

    constructor() {
        _initializeOwner(msg.sender);
        uint96 initialTokenSupply = (5_000) * 10 ** 18;
        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, msg.sender, mirror);
    }

    // External Functions

    /**
     * @dev Set the base URI.
     * @param baseURI_ The base URI to set.
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURI = baseURI_;
        emit BatchMetadataUpdate(1, (5_000));
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

    /**
     * @dev Set the bridge address.
     * @param bridgeAddress_ The bridge address to set.
     */
    function setBridgeAddress(address bridgeAddress_) external onlyOwner {
        bridgeAddress = bridgeAddress_;
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
