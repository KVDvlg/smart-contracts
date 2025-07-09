// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OwnableExtended {
    address public owner;

    enum Role { Admin, Moderator, Pauser, Treasurer }

    uint256 constant MAX_ADMINS = 2;
    uint256 constant MAX_MODERATORS = 4;

    // Для каждой роли — список адресов
    mapping(Role => address[]) private roleMembers;

    // Быстрый чек наличия роли у адреса
    mapping(address => mapping(Role => bool)) private hasRole;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoleGranted(Role role, address indexed account);
    event RoleRevoked(Role role, address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function grantRole(Role role, address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        require(!hasRole[account][role], "Already has role");

        if (role == Role.Admin) {
            require(roleMembers[Role.Admin].length < MAX_ADMINS, "Max admins reached");
        } else if (role == Role.Moderator) {
            require(roleMembers[Role.Moderator].length < MAX_MODERATORS, "Max moderators reached");
        }
        // pauser и treasurer без лимитов

        hasRole[account][role] = true;
        roleMembers[role].push(account);

        emit RoleGranted(role, account);
    }

    function revokeRole(Role role, address account) external onlyOwner {
        require(hasRole[account][role], "Account does not have role");

        hasRole[account][role] = false;
        _removeRoleMember(role, account);

        emit RoleRevoked(role, account);
    }

    function hasRoleFor(address account, Role role) external view returns (bool) {
        return hasRole[account][role];
    }

    function getRoleMembers(Role role) external view returns (address[] memory) {
        return roleMembers[role];
    }

    function _removeRoleMember(Role role, address account) internal {
        address[] storage members = roleMembers[role];
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == account) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
    }
}
