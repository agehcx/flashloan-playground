// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IFlashBorrower
 * @dev Interface for flash loan receivers
 */
interface IFlashBorrower {
    /**
     * @dev Called by the flash loan provider during a flash loan
     * @param token The address of the token being borrowed
     * @param amount The amount of tokens borrowed
     * @param fee The fee to be paid for the flash loan
     * @param data Additional data passed by the borrower
     * @return success True if the flash loan was handled successfully
     */
    function onFlashLoan(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bool success);
}