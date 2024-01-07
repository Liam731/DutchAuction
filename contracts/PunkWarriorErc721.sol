//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DutchAuction} from "./DutchAuction.sol";

contract PunkWarriorErc721 is ERC721, DutchAuction {
    string internal baseURI;

    constructor() ERC721("Punk Warrior NFT", "PWNFT") DutchAuction() {}

    function setBaseURI(string calldata baseURI_) external {
        baseURI = baseURI_;
    }

    function tansferAuctionItem(address bidder, uint256 itemIndex) external returns (bool) {
        require(msg.sender == address(this), "Only this contract can mint");
        _mint(bidder, itemIndex);
        return true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory tempBaseURI = _baseURI();
        return bytes(tempBaseURI).length > 0 ? string.concat(baseURI) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
