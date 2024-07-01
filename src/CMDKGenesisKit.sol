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


 */

import "dn404/DN404.sol";
import "dn404/DN404Mirror.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC7572} from "./interfaces/IERC7572.sol";
import {ICMDKGenesisKit} from "./interfaces/ICMDKGenesisKit.sol";

/**
 * @title CMDK Genesis Kit
 * @notice CMDK Genesis Kit begins with fungible tokens.
 * When a user has at least one base unit (10^18) amount of tokens, they will automatically receive an NFT.
 * NFTs are minted as an address accumulates each base unit amount of tokens.
 */
contract CMDKGenesisKit is DN404, Ownable, IERC7572 {
    string private _baseURI;
    string private _contractURI;

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

    /**
     * @dev Withdraw all ETH from the contract.
     */
    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    // Internal functions

    /// @inheritdoc DN404
    function _tokenURI(uint256 tokenId) internal view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
        }
    }
}
