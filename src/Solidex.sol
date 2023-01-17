// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import 'lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol';

/**
 * @title Solidex
 * @author solidoracle.eth
 * @dev I created an automatic market where the contract will hold reserves of both ETH and 🔮 Solids. These reserves will provide liquidity that allows anyone to swap between the assets.
 */
contract Solidex {

    using SafeMath for uint256; 
    IERC20 token; 

    uint256 public totalLiquidity;
    mapping (address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address, string, uint256, uint256);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address, string, uint256, uint256);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address, uint256, uint256, uint256);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(address, uint256, uint256, uint256);

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) public {
        token = IERC20(token_addr); 
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee 
     * Loads contract up with both ETH and Solids.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(tokens > 0, 'Cannot init with 0 tokens');
        require(totalLiquidity == 0, "DEX: init - already has liquidity");

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer did not transact");
        return totalLiquidity;
    }

    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {

        uint256 xInputWithFee = xInput.mul(997);
        uint256 numerator = xInputWithFee.mul(yReserves);
        uint256 denominator = (xReserves.mul(1000)).add(xInputWithFee);
        return (numerator / denominator);

    }

    /**
     * @notice sends Ether to DEX in exchange for $SLD
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {

        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 token_reserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, token_reserve);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap.");
        emit EthToTokenSwap(msg.sender, "Eth to Balloons", msg.value, tokenOutput);
        return tokenOutput;
    }

    /**
     * @notice sends $SLD tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 token_reserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, token_reserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        (bool sent, ) = msg.sender.call{ value: ethOutput }("");
        require(sent, "tokenToEth: revert in transferring eth to you!");
        emit TokenToEthSwap(msg.sender, "Balloons to ETH", ethOutput, tokenInput);
        return ethOutput;
    }

    /**
     * @notice allows deposits of $SLD and $ETH to liquidity pool
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send value when depositing");
        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;

        // 1 is added to simply be unequal to 0 in worst case scenario.
        // this is because the ration must be kept constant, so dx/x = dy/y , hence y = dx * y / x
        tokenDeposit = (msg.value.mul(tokenReserve) / ethReserve).add(1);

        // LP tokens represent your -percent- of the pool, not the exact amount.
        // In fact, with each trade, a little fee is left behind and stays in the pool. So the value of LP tokens 
        // increases with a trade but you don’t get more LP tokens, they represent your cut of the totally liquidity

        // Hence we need a function to calculate how much of the resulting output asset (LP tokens) you will get if you put 
        // in a certain amount of the input asset for a determinate ratio of assets in the pool (ration of assets in a pool = totalLiquidity) / ethReserve)

        // This gives the correct amount of liquidity token. 
        // So totalLiquidity/ethReserve is the amount of liquidity token issued per eth 
        // added to the pool. So multiplying your deposited eth by this ratio gives your portion of the pool

        // It's essentially building a price for liquidity totalLiquidity per eth in reserves.
        // Once you've got this "price" of liquidity you see how much the deposit (msg.value) is worth
        
        uint256 liquidityTokensMinted = msg.value.mul(totalLiquidity) / ethReserve;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidityTokensMinted);
        totalLiquidity = totalLiquidity.add(liquidityTokensMinted);

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        emit LiquidityProvided(msg.sender, liquidityTokensMinted, msg.value, tokenDeposit);
        return tokenDeposit;

    }

    /**
     * @notice allows withdrawal of $SLD and $ETH from liquidity pool
     */
    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {
        require(liquidity[msg.sender] >= amount, "withdraw: sender does not have enough liquidity to withdraw.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethWithdrawn;

        // ratio of the eth liquidity pool you want to withdraw, times the amount you want to withdraw
        ethWithdrawn = amount.mul(ethReserve) / totalLiquidity;
        
        // ratio of the baloon liquidity pool you want to withdraw, times the amount you want to withdraw
        uint256 tokenAmount = amount.mul(tokenReserve) / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender].sub(amount);
        totalLiquidity = totalLiquidity.sub(amount);
        (bool sent, ) = payable(msg.sender).call{ value: ethWithdrawn }("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenAmount));
        emit LiquidityRemoved(msg.sender, amount, ethWithdrawn, tokenAmount);
        return (ethWithdrawn, tokenAmount);

    }
}
