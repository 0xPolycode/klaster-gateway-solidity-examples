// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/IKlasterGatewaySingleton.sol";
import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/TestERC20.sol";

/**
    Example contract showing how easy it is to ingetrate with the Klaster Gateway contract.
    Deploy this contract to any testnet chain and then start calling functions to execute
    cross-chain actions from your Klaster generated cross-chain wallet.

    We recommend deploying this contract to Mumbai as you can easily acquire test coins on their faucet
    here: https://faucet.polygon.technology/ . Test coins must be sent to this contract address
    as the contract has to pay for Klaster fees when executing cross-chain interactions.

    Follow the steps below.
*/
contract KlasterGatewayConsumer {
   
    /**
       STEP 1: Connection to the official Klaster Gateway testnet instance obtained!
    */
    IKlasterGatewaySingleton public TESTNET_GATEWAY = IKlasterGatewaySingleton(
        0xdfF6fe22EACd7c3c4c9C3c9E9f9915026bBD98F1
    );

    /**
       STEP 2: Precomputes you Klaster Gateway address by providing your wallet which is funded with
               test coins, and a salt of your choice (for example, "my first wallet").
               Call this function after deploying the contract to check the value of your precomputed
               cross-chain address.
    */
    function generateAddressExample(string memory salt) external view returns (address) {
        return TESTNET_GATEWAY.calculateAddress(msg.sender, salt);
    }

    /**
       STEP 3: Call this function to deploy a new ERC20 Token using the generated cross-chain wallet.
               Provide the salt of the wallet you're deploying from (the same as in step 2),
               and the target chain selector where the token will be deployed at.
               You can find chain selectors at the docs:
               
               https://klaster.gitbook.io/gateway/introduction/supported-chains#chain-selectors

               NOTE 1: You need to fund this contract with some native coins (MATIC if on polygon)
                       in order for the call to succeed. As you can see in the implementation function,
                       we need to precompute protocol fees and send that value when executing Klaster
                       Gateway transaction or else the call will fail. This contract needs to hold
                       sufficient amount of native coins at its balance to be able to pay for fees.

               NOTE 2: Token will be deployed using the create2 method, so you also need to provide 
                       a random string used for salt, as the last aprameter.
                       To precompute an address of the token, call the precomputeTokenAddress(),
                       we will use this address in step 4.

               NOTE 3: Once you execute this function successfully, you can monitor the status of
                       the cross-chain call by visiting https://ccip.chain.link/ and pasting your
                       transaction hash obtained by executing this function.
    */
    function deployTokenExample(
        uint64[] memory targetChainSelectors,
        string memory gatewayWalletSalt,
        string memory tokenName,
        string memory tokenSymbol,
        string memory create2Salt
    ) external {
        uint256 fees = TESTNET_GATEWAY.calculateExecuteFee(
            msg.sender,
            targetChainSelectors,
            gatewayWalletSalt,
            address(0),                                 // set to 0x0 for contract deployment
            0,                                          // value is 0 (no value transfer)
            _getBytecodeERC20(tokenName, tokenSymbol),  // fetches the bytecode of the contract implementation together with constructor params
            2_000_000,                                  // safe gas limit
            keccak256(abi.encode(create2Salt))          // salt used to deploy contract with create2
        );

        // after calculating fees, execute the call with the same data
        TESTNET_GATEWAY.execute{value: fees}( // Klaster protocol fees. Must be calculated & sent for the call to succeed
            targetChainSelectors,
            gatewayWalletSalt,
            address(0),
            0,
            _getBytecodeERC20(tokenName, tokenSymbol),
            2_000_000,
            keccak256(abi.encode(create2Salt))
        );
    }
    function precomputeTokenAddress(
        string memory gatewayWalletSalt,
        string memory tokenName,
        string memory tokenSymbol,
        string memory create2Salt
    ) external view returns (address) {
        return TESTNET_GATEWAY.calculateCreate2Address(
            msg.sender,
            gatewayWalletSalt,
            _getBytecodeERC20(tokenName, tokenSymbol),
            keccak256(abi.encode(create2Salt))
        );
    }

    /**
        STEP 4: Once we deployed a token on a destination chain successfully, 100 tokens were minted on the
                destination chain to the deployer wallet (klaster gateway generated subwallet).
                We will now show how to move 1 token from this subwallet to address(0), by triggering
                the process through the klaster gateway.

                We will use the same cross-chain wallet salt (used in steps 2 & 3).
                The token address we deployed must be fetched by calling the precomputeTokenAddress() function,
                as we will use this address to execute the transfer function remotely on the token.

                NOTE: Once you execute this function successfully, you can monitor the status of
                the cross-chain call by visiting https://ccip.chain.link/ and pasting your
                transaction hash obtained by executing this function.
    */
    function burnOneTokenExample(
        uint64[] memory targetChainSelectors, // set to the same chain selector as the one in step 3
        string memory gatewayWalletSalt, // gateway wallet salt used in steps 2 & 3
        address tokenAddress // deployed in step 3 and computed using the precomputeTokenAddress() function
    ) external {
        bytes memory executePayload = abi.encodeWithSignature( // first we encode the transfer token data
            "transfer(address,uint256)",                       // to burn 1 token (send it to address 0)
            address(0),     // receiver is address(0)
            1 * 10e18       // amount = 1 token (10e18 in wei)
        );
        uint256 fees = TESTNET_GATEWAY.calculateExecuteFee(
            msg.sender,
            targetChainSelectors,
            gatewayWalletSalt,
            tokenAddress,           // address of the token we're interacting with on the remote chain
            0,                      // value is 0 (no value transfer)
            executePayload,         // function we want to execute on the remote chain (transfer 1 token)
            2_000_000,              // safe gas limit
            0x0                     // extraData param not used
        );

        // after calculating fees, execute the call with the same data
        TESTNET_GATEWAY.execute{value: fees}( // Klaster protocol fees. Must be calculated & sent for the call to succeed
            targetChainSelectors,
            gatewayWalletSalt,
            tokenAddress,
            0,
            executePayload,
            2_000_000,
            0x0
        );
    }

    /********************* HELPER FUNCTIONS *********************/

    // get the bytecode of the ERC20 token contract with input constructor values
    function _getBytecodeERC20(string memory name, string memory symbol) private pure returns (bytes memory) {
        bytes memory bytecode = type(TestERC20).creationCode;
        return abi.encodePacked(bytecode, abi.encode(name, symbol));
    }

}
