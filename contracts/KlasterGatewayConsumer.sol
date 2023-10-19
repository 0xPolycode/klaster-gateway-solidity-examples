// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/IKlasterGatewaySingleton.sol";
import "https://github.com/0xPolycode/klaster-gateway-solidity-examples/blob/master/contracts/TestERC20.sol";

/**
    Example contract showing how easy it is to ingetrate with the Klaster Gateway contract.
    Deploy this contract to any testnet chain and then start calling functions to execute
    cross-chain actions from your Klaster generated cross-chain wallet.

    We recommend deploying this contract to Optimism Görli as you can easily acquire test coins
    on their faucet. here: https://faucet.quicknode.com/optimism/goerli . 
    Test coins must be sent to this contract address as the contract has to
    pay for Klaster fees when executing cross-chain interactions.
    
    NOTE: We recommend sending at least 0.01 test ETH to this contract after deploying on Optimism Görli. 
    Functions are implemented to send messages to Arbitrum Görli (chain selector: 6101244977088475029).
    That's because the messages from Optimism Görli to Arbitrum Görli are relatively cheap and you will
    be able to test everything out.
*/
contract KlasterGatewayConsumer {
   
    /**
       CONFIG PARAMETERS
    */

    // klaster gateway testnet instance
    IKlasterGatewaySingleton public GATEWAY = IKlasterGatewaySingleton(
        0xdfF6fe22EACd7c3c4c9C3c9E9f9915026bBD98F1
    );

    // salt used for klaster wallet computation
    string public GATEWAY_SALT = "salt";

    // test token data
    string public TOKEN_NAME = "Test Token";
    string public TOKEN_SYMBOL = "TT";
    string public TOKEN_CREATE2_SALT = "random salt";

    // target chain selector (arbitrum goerli)
    uint64[] public DEST_CHAIN_SELECTOR = [ 6101244977088475029 ]; // store as a list as defined by gateway

    // deployed token address holder
    address public DEPLOYED_TOKEN_ADDRESS;

    /**
        STEP 1: Call this function to see what's your generated klaster gateway address.
                This address is built from master wallet (this contract) & random salt string ("SALT").
                This means only **this** contract can get control of the generated address(es).

                This address is a precomputed static call. It exists by default and is ready to be used
                without any state change or activation.
    */
    function precomputeKlasterGatewayAddress() external view returns (address) {
        return GATEWAY.calculateAddress(address(this), GATEWAY_SALT);
    }

    /**
       STEP 2: Call this function to deploy a new ERC20 Token to a target chain (Arbitrum in this case)
               using the klaster gateway wallet.
               
               NOTE 1: You need to fund this contract with some native coins (test ETH on optimism goerli)
                       in order for the call to succeed. As you can see in the implementation function,
                       we need to precompute protocol fees and send that value when executing Klaster
                       Gateway transaction or else the call will fail. This contract needs to hold
                       sufficient amount of native coins at its balance to be able to pay for fees.

               NOTE 2: Token will be deployed using the create2 method (klaster gateway supports this).
                       Therefore, token's address can be precomputed. Call the precomputeTokenAddress() to
                       check where the token is going to be deployed on the Arbitrum Görli.

               NOTE 3: Once you execute this function successfully, you can monitor the status of
                       the cross-chain call by visiting https://ccip.chain.link/ and pasting your
                       transaction hash obtained by executing this function.
    */
    function deployTokenToArbitrum() external {

        // calculate Klaster Gateway fee
        uint256 fees = GATEWAY.calculateExecuteFee(
            address(this),
            DEST_CHAIN_SELECTOR,
            GATEWAY_SALT,
            address(0),                                        // set to 0x0 for contract deployment
            0,                                                 // value is 0 (no value transfer)
            _getBytecodeERC20(TOKEN_NAME, TOKEN_SYMBOL),       // fetches the bytecode of the contract implementation together with constructor params
            2_000_000,                                         // safe gas limit
            keccak256(abi.encode(TOKEN_CREATE2_SALT))          // salt used to deploy contract with create2
        );

        // check if contract balance is enough to execute Klaster call
        require(
            address(this).balance >= fees,
            "Insufficient funds. Send more test ETH to this contract to execute Klaster Gateway call."
        );

        // after calculating fees, execute the call with the same data
        (bool success,,) = GATEWAY.execute{value: fees}( // Klaster protocol fees. Must be calculated & sent for the call to succeed
            DEST_CHAIN_SELECTOR,
            GATEWAY_SALT,
            address(0),
            0,
            _getBytecodeERC20(TOKEN_NAME, TOKEN_SYMBOL),
            2_000_000,
            keccak256(abi.encode(TOKEN_CREATE2_SALT))
        );

        // require operation success
        require(success, "Gateway operation failed.");

        // save the deployed token address
        DEPLOYED_TOKEN_ADDRESS = precomputeTokenAddress();
    }

    function precomputeTokenAddress() public view returns (address) {
        return GATEWAY.calculateCreate2Address(
            address(this),
            GATEWAY_SALT,
            _getBytecodeERC20(TOKEN_NAME, TOKEN_SYMBOL),
            keccak256(abi.encode(TOKEN_CREATE2_SALT))
        );
    }

    /**
        STEP 3: Once we deployed a token on a destination chain successfully, 100 tokens were minted on the
                destination chain to the klaster gateway wallet controlled by this contract.
                This is something you can verify by inspecting the STEP-2 transaction hash on the CCIP explorer.

                We will now show how to move 1 token from the klaster gateway wallet to address(0),
                or in other words "burn token", on arbitrum görli, by triggering the process through
                the klaster gateway.

                NOTE: Once you execute this function successfully, you can monitor the status of
                the cross-chain call by visiting https://ccip.chain.link/ and pasting your
                transaction hash obtained by executing this function.
    */
    function burnTokenOnArbitrum() external {

        // make sure STEP 2 (token deployment) was executed before burning
        require(DEPLOYED_TOKEN_ADDRESS != address(0), "Token not deployed. Deploy token first.");

        // encode ERC20 transfer function
        bytes memory executePayload = abi.encodeWithSignature(
            "transfer(address,uint256)",    // function signature
            address(0),                     // receiver is address(0)
            1 * 10e18                       // amount = 1 token (10e18 in wei)
        );

        // calculate Klaster Gateway fee
        uint256 fees = GATEWAY.calculateExecuteFee(
            msg.sender,
            DEST_CHAIN_SELECTOR,
            GATEWAY_SALT,
            DEPLOYED_TOKEN_ADDRESS,     // address of the token we're interacting with on the remote chain
            0,                          // value is 0 (no value transfer)
            executePayload,             // function we want to execute on the remote chain (transfer 1 token)
            2_000_000,                  // safe gas limit
            0x0                         // extraData param not used
        );

        // check if contract balance is enough to execute Klaster call
        require(
            address(this).balance >= fees,
            "Insufficient funds. Send more test ETH to this contract to execute Klaster Gateway call."
        );

        // after calculating fees, execute the call with the same data
        GATEWAY.execute{value: fees}( // Klaster protocol fees. Must be calculated & sent for the call to succeed
            DEST_CHAIN_SELECTOR,
            GATEWAY_SALT,
            DEPLOYED_TOKEN_ADDRESS,
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

    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

}
