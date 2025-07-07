// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MockSimpleStorage
/// @notice A mock version of FHEUintSimpleStorage without encryption logic

contract MockSimpleStorage {
    uint32 private storedValue;

    /// @notice Store a value (mocking encrypted input)
    /// @param _value The "encrypted" value (plain uint32 for mock)
    function store(uint32 _value) external {
        storedValue = _value;
    }

    /// @notice Retrieve the stored value (mocking encrypted output)
    /// @return The stored value as plain uint32
    function retrieve() external view returns (uint32) {
        return storedValue;
    }
}
