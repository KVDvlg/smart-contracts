// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandRegistryNFT is ERC721, Ownable {
    uint256 public nextTokenId;

    struct LandData {
        string cadastralNumber;
        string location;
        address currentOwner;
    }

    // Mapping от tokenId к данным о земле
    mapping(uint256 => LandData) public landData;

    // История владельцев токена
    mapping(uint256 => address[]) public ownershipHistory;

    // Роль регистратора
    mapping(address => bool) public isRegistrar;

    // События
    event RegistrarAdded(address registrar);
    event RegistrarRemoved(address registrar);
    event LandRegistered(uint256 tokenId, string cadastralNumber, address owner);
    event OwnerChanged(uint256 tokenId, address oldOwner, address newOwner);

    constructor(address initialOwner) ERC721("LandRegistryNFT", "LAND") Ownable(initialOwner) {}

    // Назначить регистратора
    function addRegistrar(address registrar) external onlyOwner {
        isRegistrar[registrar] = true;
        emit RegistrarAdded(registrar);
    }

    // Удалить регистратора
    function removeRegistrar(address registrar) external onlyOwner {
        isRegistrar[registrar] = false;
        emit RegistrarRemoved(registrar);
    }

    modifier onlyRegistrar() {
        require(isRegistrar[msg.sender], "Not a registrar");
        _;
    }

    // Функция для регистрации нового участка земли
    function registerLand(
        string memory cadastralNumber,
        string memory location,
        address to
    ) external onlyRegistrar {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(to, tokenId);

        landData[tokenId] = LandData({
            cadastralNumber: cadastralNumber,
            location: location,
            currentOwner: to
        });

        ownershipHistory[tokenId].push(to);

        emit LandRegistered(tokenId, cadastralNumber, to);
    }

    // Получить текущего владельца из LandData (не путать с ownerOf)
    function getCurrentOwner(uint256 tokenId) external view returns (address) {
        require(exists(tokenId), "Token does not exist");
        return landData[tokenId].currentOwner;
    }

    // Получить историю владельцев
    function getOwnershipHistory(uint256 tokenId) external view returns (address[] memory) {
        require(exists(tokenId), "Token does not exist");
        return ownershipHistory[tokenId];
    }

    // Обновить владельца (с логированием)
    function updateOwner(uint256 tokenId, address newOwner) external onlyRegistrar {
        require(exists(tokenId), "Token does not exist");

        address oldOwner = landData[tokenId].currentOwner;

        landData[tokenId].currentOwner = newOwner;
        ownershipHistory[tokenId].push(newOwner);

        _transfer(ownerOf(tokenId), newOwner, tokenId);

        emit OwnerChanged(tokenId, oldOwner, newOwner);
    }

    // Проверка существования токена (вместо _exists)
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
