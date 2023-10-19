// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/IKlasterGatewaySingleton.sol";

/**
    Example contract showing how easy it is to ingetrate with the Klaster Gateway contract.
    Deploy this contract to any testnet chain and then start calling functions to execute
    cross-chain actions from your Klaster generated cross-chain wallet.

    We recommend deploying this contract to Mumbai as you can easily acquire test coins on their faucet
    here: https://faucet.polygon.technology/

    Then follow the steps below to play with Gateway.
*/
contract KlasterGatewayConsumer {
   
    /**
       STEP 1: Connection to the official Klaster Gateway testnet instance obtained!
    */
    IKlasterGatewaySingleton public TESTNET_GATEWAY = IKlasterGatewaySingleton(
        0xdfF6fe22EACd7c3c4c9C3c9E9f9915026bBD98F1
    );

    /**
       STEP 2: Generate you Klaster Gateway address by providing your wallet which is funded with
               test coins, and a salt of your choice (for example, "my first wallet").
               Call this function after deploying the contract to calculate the address.
    */
    function generateAddressExample(address caller, string memory salt) external view returns (address) {
        return TESTNET_GATEWAY.calculateAddress(caller, salt);
    }

    /**
       STEP 3: Call this function to deploy a new ERC20 Token using the generated cross-chain wallet.
               Provide the salt of the wallet you're deploying from (the same as in step1),
               and the target chain selector where the token will be deployed at.
               You can find chain selectors at the docs:
               
               https://klaster.gitbook.io/gateway/introduction/supported-chains#chain-selectors

               IMPORTANT: you need to provide the `msg.value` when calling this function to pay for
                          protocol fees. Calculate the protocol fee by calling the getDeployTokenExampleFee()
                          and providing the same parameters as when actually calling this function.
    */
    function deployTokenExample() public {

    }
    function getDeployTokenExampleFee() external view returns (uint256) {
        return 0;
    }

    /**
        > Batch deploys ERC20 token on multiple chains all at the same address (using create2).
        > ERC20 implementation will automatically mint 100 tokens to the deployers
          cross-chain wallet on all chains.
    */
    function batchDeployTokenCreate2Example() public {

    }




    // get the bytecode of the ERC20 token contract with input constructor values
    function _getBytecode(address owner) private pure returns (bytes memory) {
        bytes memory bytecode = type(KlasterGatewayWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(owner));
    }

}
