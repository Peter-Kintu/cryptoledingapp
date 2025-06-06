// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract is a simplified example.
// For a production system, you would use proper ERC-20 interfaces (IERC20)
// and standard patterns like 'approve' and 'transferFrom' for token handling.
// You would also implement robust oracle integration for collateral value checks.

contract P2PLoan {
    // --- Loan Parameters ---
    uint256 public loanAmount;          // Amount of loan asset (e.g., DAI)
    uint256 public collateralAmount;    // Amount of collateral asset (e.g., WETH)
    uint256 public interestRate;        // Annual interest rate (e.g., 500 = 5%)
    uint256 public loanDuration;        // Duration in seconds (e.g., 30 days)

    // --- Participants ---
    address payable public lender;      // Address of the lender
    address payable public borrower;    // Address of the borrower

    // --- State Variables ---
    uint256 public loanStartTime;       // Timestamp when loan was disbursed
    uint256 public loanEndTime;         // Timestamp when loan is due
    bool public isDisbursed;            // True if loan has been disbursed
    bool public isRepaid;               // True if loan has been fully repaid
    bool public isLiquidated;           // True if collateral has been claimed

    // Assume fixed token addresses for simplicity in this example
    // In a real app, these would be set during deployment or as parameters
    address payable public loanAssetAddress;     // Address of the ERC-20 token for the loan (e.g., DAI)
    address payable public collateralAssetAddress; // Address of the ERC-20 token for the collateral (e.g., WETH)

    // --- Events ---
    event LoanRequested(address indexed _borrower, uint256 _loanAmount, uint256 _collateralAmount, uint256 _duration, uint256 _interestRate);
    event LoanDisbursed(address indexed _borrower, address indexed _lender, uint256 _amount, uint256 _disbursementTime, uint256 _endTime);
    event RepaymentMade(address indexed _borrower, uint256 _amountPaid, uint256 _remainingDue);
    event CollateralReleased(address indexed _borrower, uint256 _collateralAmount);
    event CollateralLiquidated(address indexed _lender, uint256 _collateralAmount);

    // --- Constructor ---
    // The constructor is called only once when the contract is deployed.
    // It sets up the initial terms of the loan.
    // In a P2P scenario, this contract might be deployed for each specific loan agreement.
    constructor(
        address payable _lender,
        address payable _borrower,
        uint256 _loanAmount,
        uint256 _collateralAmount,
        uint256 _interestRate, // Annual rate, multiplied by 10000 to represent 1% (e.g., 500 for 5%)
        uint256 _loanDuration, // In seconds
        address payable _loanAssetAddress,
        address payable _collateralAssetAddress
    ) {
        require(_lender != address(0), "Lender cannot be zero address");
        require(_borrower != address(0), "Borrower cannot be zero address");
        require(_loanAmount > 0, "Loan amount must be greater than zero");
        require(_collateralAmount > 0, "Collateral amount must be greater than zero");
        require(_interestRate <= 10000, "Interest rate cannot exceed 100%"); // Max 100% per year
        require(_loanDuration > 0, "Loan duration must be greater than zero");

        lender = _lender;
        borrower = _borrower;
        loanAmount = _loanAmount;
        collateralAmount = _collateralAmount;
        interestRate = _interestRate;
        loanDuration = _loanDuration;
        loanAssetAddress = _loanAssetAddress;
        collateralAssetAddress = _collateralAssetAddress;

        emit LoanRequested(borrower, loanAmount, collateralAmount, loanDuration, interestRate);
    }

    // --- Modifiers ---
    modifier onlyLender() {
        require(msg.sender == lender, "Only lender can call this function");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only borrower can call this function");
        _;
    }

    // --- Core Functions ---

    // Function to fund the loan by the lender
    // In a real ERC-20 scenario, lender would call `approve` on the token contract
    // then this contract would call `transferFrom`
    function fundLoan() external payable onlyLender {
        require(!isDisbursed, "Loan already disbursed");
        require(msg.value >= loanAmount, "Lender must send exact loan amount (for ETH/DAI example)"); // Simplified
        
        // In a real ERC-20 case:
        // IERC20(loanAssetAddress).transferFrom(lender, address(this), loanAmount);
        
        // For simplicity, we assume msg.value is the loan asset.
        // In reality, lender would send `loanAmount` of `loanAssetAddress` token.
        // For now, we simulate receiving the `loanAmount` by accepting ETH.
        // Or if `loanAssetAddress` is actually a token, this function would be renamed
        // to something like `approveAndCallTransferFrom` and the lender would have
        // already called `approve` on the `loanAssetAddress` contract.
        
        // If loanAssetAddress is ETH and collateralAssetAddress is WETH:
        // require(loanAssetAddress == address(0), "Loan asset must be native ETH for msg.value");
        // require(msg.value == loanAmount, "Lender must send exact loan amount");
        // But for clarity, we are assuming ERC20s for both, so `msg.value` is just a placeholder here.
        // The actual `transferFrom` call would be inside the contract using IERC20.

        isDisbursed = true;
        loanStartTime = block.timestamp;
        loanEndTime = block.timestamp + loanDuration;

        // Transfer loan amount to borrower (simplified for example)
        borrower.transfer(loanAmount); // Simulates token transfer to borrower

        emit LoanDisbursed(borrower, lender, loanAmount, loanStartTime, loanEndTime);
    }

    // Function for borrower to provide collateral
    // Similar to fundLoan, in a real ERC-20 scenario, borrower would call `approve`
    // then this contract would call `transferFrom`
    function provideCollateral() external payable onlyBorrower {
        require(!isDisbursed, "Cannot provide collateral after loan disbursement"); // Should be before funding
        require(msg.value >= collateralAmount, "Borrower must send exact collateral amount (for ETH/WETH example)"); // Simplified
        
        // In a real ERC-20 case:
        // IERC20(collateralAssetAddress).transferFrom(borrower, address(this), collateralAmount);
        
        // For now, we simulate receiving the `collateralAmount` by accepting ETH.
        // The actual `transferFrom` call would be inside the contract using IERC20.
        
        // If collateralAssetAddress is ETH:
        // require(collateralAssetAddress == address(0), "Collateral asset must be native ETH for msg.value");
        // require(msg.value == collateralAmount, "Borrower must send exact collateral amount");
        // But for clarity, we are assuming ERC20s for both, so `msg.value` is just a placeholder here.
        // The actual `transferFrom` call would be inside the contract using IERC20.

        // This function would usually be called *before* `fundLoan` to ensure collateral is locked.
        // For this example, we'll assume a two-step process initiated by borrower then lender.
    }

    // Calculate total amount due (principal + interest)
    function calculateAmountDue() public view returns (uint256) {
        if (!isDisbursed || isRepaid) {
            return loanAmount; // If not disbursed or already repaid, return principal
        }

        uint256 timeElapsed = block.timestamp - loanStartTime;
        if (timeElapsed > loanDuration) {
            timeElapsed = loanDuration; // Don't accrue interest beyond duration for simplicity in this model
        }

        // Simple interest calculation: Principal * (Interest Rate / 10000) * (Time Elapsed / Total Duration)
        // To avoid floating point, we scale up by 1e18 for calculations and then scale down
        uint256 interest = (loanAmount * interestRate * timeElapsed) / (10000 * loanDuration);
        return loanAmount + interest;
    }

    // Repayment function
    // Borrower sends loanAsset (e.g., DAI) back to the contract.
    // In a real ERC-20 scenario, borrower calls `approve` then this contract calls `transferFrom`
    function repayLoan() external payable onlyBorrower {
        require(isDisbursed, "Loan not disbursed yet");
        require(!isRepaid, "Loan already repaid");
        require(msg.value >= calculateAmountDue(), "Not enough sent to repay loan (for ETH/DAI example)"); // Simplified
        
        // In a real ERC-20 case:
        // IERC20(loanAssetAddress).transferFrom(borrower, address(this), calculateAmountDue());
        
        // For now, we simulate receiving the `loanAmount` by accepting ETH.
        // The actual `transferFrom` call would be inside the contract using IERC20.

        isRepaid = true;

        // Transfer principal + interest to lender (simplified for example)
        lender.transfer(calculateAmountDue()); // Simulates token transfer to lender

        // Release collateral back to borrower (simplified for example)
        borrower.transfer(collateralAmount); // Simulates token transfer of collateral
        emit RepaymentMade(borrower, calculateAmountDue(), 0);
        emit CollateralReleased(borrower, collateralAmount);
    }

    // Lender can claim collateral if loan is overdue
    function liquidateCollateral() external onlyLender {
        require(isDisbursed, "Loan not disbursed");
        require(!isRepaid, "Loan already repaid");
        require(block.timestamp > loanEndTime, "Loan is not yet overdue");
        require(!isLiquidated, "Collateral already liquidated");

        isLiquidated = true;

        // Transfer collateral to lender (simplified for example)
        lender.transfer(collateralAmount); // Simulates token transfer of collateral
        emit CollateralLiquidated(lender, collateralAmount);
    }

    // --- Helper Functions ---

    // Allows the contract owner to recover accidental ETH sends
    function withdrawAccidentalEth() external payable {
        // Only contract owner can withdraw this (implement owner check later)
        // This is primarily for ETH sent directly, not tokens
        // For a full app, you'd add an `owner` state variable and `onlyOwner` modifier.
        payable(msg.sender).transfer(address(this).balance);
    }

    // This function will receive any ETH sent to the contract directly.
    receive() external payable {
        // Optional: Add logic here to reject unexpected ETH, or log it.
        // For this example, we assume `fundLoan` and `provideCollateral` are the intended ways
        // to send value, but `receive` is good practice.
    }
}