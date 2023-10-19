// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IKlasterGatewaySingleton.sol";

/**
    Example contract showing how easy it is to ingetrate with the Klaster Gateway contract.
    Deploy this contract to any testnet chain and then start calling functions to execute
    cross-chain actions from your Klaster generated cross-chain wallet.

    We recommend deploying to Mumbai as you can easily acquire test coins on their faucet
    here: https://faucet.polygon.technology/
*/
contract KlasterGatewayConsumer {
   
    /**
       STEP 1: Connect to the official Klaster Gateway testnet instance!
    */
    IKlasterGatewaySingleton public TESTNET_GATEWAY = IKlasterGatewaySingleton(
        0xdfF6fe22EACd7c3c4c9C3c9E9f9915026bBD98F1
    );

    /**
       STEP 2: Generate you Klaster Gateway address by providing your wallet which is funded with
               test coins, and a salt of your choice (for example, "my first wallet".
    */
    function generateAddressExample(address caller, string memory salt) external view returns (address) {
        return TESTNET_GATEWAY.calculateAddress(caller, salt);
    }

    /**
       STEP 3: Deploy a new ERC20 Token using the generated cross-chain wallet.
               Provide the salt of the wallet you're deploying from (the same as in step1),
               and the target chain selector where the token will be deployed at.
               You can find chain selectors at the docs:
               
               https://klaster.gitbook.io/gateway/introduction/supported-chains#chain-selectors
    */
    function deployTokenExample() public {

    }

    /**
        > Batch deploys ERC20 token on multiple chains all at the same address (using create2).
        > ERC20 implementation will automatically mint 100 tokens to the deployers
          cross-chain wallet on all chains.
    */
    function batchDeployTokenCreate2Example() public {

    }

}
