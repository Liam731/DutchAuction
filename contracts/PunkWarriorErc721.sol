//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/console.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DutchAuction} from "./DutchAuction.sol";
import {SToken} from "./protocol/SToken.sol";

contract PunkWarriorErc721 is ERC721, DutchAuction {
    string internal baseURI;

    constructor(SToken sToken) ERC721("Punk Warrior NFT", "PWNFT") DutchAuction(sToken) {}

    function setBaseURI(string calldata baseURI_) external {
        baseURI = baseURI_;
    }

    function tansferAuctionItem(address bidder, uint256 itemIndex) external returns (bool) {
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
