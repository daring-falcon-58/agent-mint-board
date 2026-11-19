// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/AgentMintBoard.sol";

/// @notice Minimal mock of the SPACE ID Agent ID ERC-721 (only balanceOf).
contract MockAgentID {
    mapping(address => uint256) public balances;

    function setBalance(address who, uint256 amount) external {
        balances[who] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }
}

contract AgentMintBoardTest is Test {
    AgentMintBoard board;
    MockAgentID agentId;

    address curator = address(0xC0FFEE);
    address holderA = address(0xA11CE);
    address holderB = address(0xB0B);
    address noId = address(0x9999);
    address mintContract = address(0x1234);

    function setUp() public {
        agentId = new MockAgentID();
        agentId.setBalance(holderA, 1);
        agentId.setBalance(holderB, 1);
        agentId.setBalance(curator, 1);
        board = new AgentMintBoard(address(agentId), curator);
    }

    function testRegisterOnlyCurator() public {
        vm.prank(holderA);
        vm.expectRevert("curator only");
        board.registerMint(mintContract, "Test Mint", "https://example.com", 100);
        vm.prank(curator);
        uint256 id = board.registerMint(mintContract, "Test Mint", "https://example.com", 100);
        assertEq(id, 0);
        assertEq(board.mintCount(), 1);
    }

    function testClaimRequiresAgentId() public {
        vm.prank(curator);
        board.registerMint(mintContract, "Test Mint", "", 100);
        vm.prank(noId);
        vm.expectRevert("Agent ID required");
        board.claim(0);
    }

    function testClaimOncePerHolder() public {
        vm.prank(curator);
        board.registerMint(mintContract, "Test Mint", "", 2);
        vm.prank(holderA);
        board.claim(0);
        assertTrue(board.hasClaimed(0, holderA));
        vm.prank(holderA);
        vm.expectRevert("already claimed");
        board.claim(0);
        vm.prank(holderB);
        board.claim(0);
        AgentMintBoard.Mint memory m = board.getMint(0);
        assertEq(m.claims, 2);
    }

    function testClaimRespectsMaxClaims() public {
        vm.prank(curator);
        board.registerMint(mintContract, "Test Mint", "", 1);
        vm.prank(holderA);
        board.claim(0);
        vm.prank(holderB);
        vm.expectRevert("claims full");
        board.claim(0);
    }

    function testDeactivateBlocksClaims() public {
        vm.prank(curator);
        board.registerMint(mintContract, "Test Mint", "", 100);
        vm.prank(curator);
        board.deactivate(0);
        vm.prank(holderA);
        vm.expectRevert("mint inactive");
        board.claim(0);
    }

    function testProposeRequiresAgentId() public {
        vm.prank(noId);
        vm.expectRevert("Agent ID required");
        board.proposeMint(mintContract, "Suspicious Mint");
        vm.prank(holderA);
        board.proposeMint(mintContract, "Good Mint"); // emits, no revert
    }

    function testTransferCurator() public {
        vm.prank(holderA);
        vm.expectRevert("curator only");
        board.transferCurator(holderA);
        vm.prank(curator);
        board.transferCurator(holderB);
        assertEq(board.curator(), holderB);
    }

    function testConstructorRejectsZeroAddresses() public {
        vm.expectRevert("zero agent id");
        new AgentMintBoard(address(0), curator);
        vm.expectRevert("zero curator");
        new AgentMintBoard(address(agentId), address(0));
    }
}
