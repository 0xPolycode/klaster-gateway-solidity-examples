// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/IKlasterGatewaySingleton.sol";
import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/TestERC20.sol";

/**
 * Batch deployment example using Klaster Gateway to deploy simple ERC20 token
 * across all the supported chains in one transaction. The token will be deployed
 * at the same address on all chains since we use create2 opcode.
 * 
 * This is how any arbitrary contract can be deployed by using similar approach.
 * Make sure to fund this contract with enough native coins in order to pay for batch
 * deployment fee. The total fee can be precalculated by calling the `getBatchDeployFee()`.
 */
contract KlasterGatewayBatchDeployer {

    /**
       CONFIG PARAMETERS
    */

    // klaster gateway testnet instance
    IKlasterGatewaySingleton private GATEWAY = IKlasterGatewaySingleton(
        0xdfF6fe22EACd7c3c4c9C3c9E9f9915026bBD98F1
    );

    // target chains to use for multichain deployment
    uint64[] private TARGET_CHAINS = [
        16015286601757825753, // ETH Sepolia
        2664363617261496610,  // Optimism Görli
        6101244977088475029,  // Arbitrum Görli
        14767482510784806043, // Avax Fuji
        12532609583862916517, // Polygon Mumbai
        5790810961207155433   // Base Görli
    ];

    // klaster gateway deployer wallet
    string private GATEWAY_SALT = "my-klaster-erc20-deployer-v1";

    /**
     * Deploys ERC20 token implementation to all Klaster Gateway supported chains in one transaction.
     * Address can be precomuputed by calling the `getTokenCreate2Address()` and providing the same data as here.
     * To pay for cross-chain deployment fees, this Deployer contract must be funded with some amount of native
     * coins in order to execute multiple cross-chain calls.
     * 
     * This function will deploy an ERC20 token implementation which automatically mints 100 tokens to the
     * deployers wallet.
     * 
     * NOTE: After executing the transaction, track the cross chain status of the operation by
     *       visiting https://ccip.chain.link/ and checking the mesages status.
     *       Cross-chain actions will be executed in parallel and should be settled in around 20 mins.
     * 
     * @param tokenName ERC20 token name
     * @param tokenSymbol ERC20 token symbol
     * @param create2Salt Create2 salt used for contract deployment
     */
    function batchDeployToken(
        string memory tokenName,
        string memory tokenSymbol,
        string memory create2Salt
    ) {

        // calculate Klaster Gateway fee
        uint256 fees = getBatchDeployFee(tokenName, tokenSymbol, create2Salt);

        // check if contract balance is enough to execute Klaster call
        require(
            address(this).balance >= fees,
            "Insufficient funds. Send more test ETH to this contract to execute multichain deployment."
        );

        // after calculating fees, execute the call with the same data
        (bool success,,) = GATEWAY.execute{value: fees}( // Klaster protocol fees. Must be precalculated & sent for the call to succeed
            TARGET_CHAINS,
            GATEWAY_SALT,
            address(0),
            0,
            _getBytecodeERC20(tokenName, tokenSymbol),
            2_000_000,
            keccak256(abi.encode(create2Salt))
        );

        // require operation success
        require(success, "Multichain deployment failed.");

    }
    
    // precomputes the token addrees for given parameters
    function precomputeBatchDeployAddress(
        string memory tokenName,
        string memory tokenSymbol,
        string memory create2Salt
    ) external view returns (address) {
        return GATEWAY.calculateCreate2Address(
            address(this),
            GATEWAY_SALT,
            _getBytecodeERC20(tokenName, tokenSymbol),
            keccak256(abi.encode(create2Salt))
        );
    }

    // precomputes the total cost in native coin to pay 
    // for executing the batch deployment operation
    function getBatchDeployFee(
        string memory tokenName,
        string memory tokenSymbol,
        string memory create2Salt
    ) public view returns (uint256) {
        return GATEWAY.calculateExecuteFee(
            address(this),
            TARGET_CHAINS,
            GATEWAY_SALT,
            address(0),                                         // set to 0x0 for contract deployment
            0,                                                  // value is 0 (no value transfer)
            _getBytecodeERC20(tokenName, tokenSymbol),          // fetches the bytecode of the contract implementation together with constructor params
            2_000_000,                                          // safe gas limit
            keccak256(abi.encode(create2Salt))                  // salt used to deploy contract with create2
        );
    }

    /********************* HELPER FUNCTIONS *********************/

    // get the bytecode of the ERC20 token contract with input constructor values
    function _getBytecodeERC20(string memory name, string memory symbol) private pure returns (bytes memory) {
        bytes memory bytecode = type(TestERC20).creationCode;
        return abi.encodePacked(bytecode, abi.encode(name, symbol));
    }

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

}
