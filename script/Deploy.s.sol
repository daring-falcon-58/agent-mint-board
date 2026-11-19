// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/AgentMintBoard.sol";

contract Deploy is Script {
    address constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address constant CURATOR = 0x580080CE9269780241d76A40A7b69aE9f6dcf7cc; // oxjhon.ai

    function run() external returns (AgentMintBoard board) {
        vm.broadcast();
        board = new AgentMintBoard(AGENT_ID, CURATOR);
    }
}
