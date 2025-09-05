# ConectCredit

A decentralized peer-to-peer lending platform built on the Stacks blockchain, enabling direct lending and borrowing without traditional intermediaries.

## Features

- **Peer-to-Peer Lending**: Direct lending between users without banks or traditional institutions
- **Collateral-Backed Loans**: All loans require STX collateral to minimize default risk
- **Flexible Interest Rates**: Borrowers can set competitive interest rates up to 20%
- **Reputation System**: Track user lending/borrowing history and reputation scores
- **Automated Collateral Claims**: Lenders can claim collateral if loans default
- **Platform Fee Structure**: Transparent 2.5% platform fee on successful loans
- **Real-time Loan Tracking**: Monitor loan status, due dates, and repayment schedules

## Architecture

### Smart Contract Components

#### Data Structures
- **Loans Map**: Stores all loan information including borrower, lender, amounts, and status
- **User Stats Map**: Tracks individual user statistics and reputation scores
- **Global Variables**: Manages loan IDs, platform fees, and maximum interest rates

#### Core Functions
- `create-loan-request`: Borrowers create loan requests with collateral
- `fund-loan`: Lenders fund approved loan requests
- `repay-loan`: Borrowers repay loans with interest to reclaim collateral
- `claim-collateral`: Lenders claim collateral from defaulted loans

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks Wallet](https://www.hiro.so/wallet) for mainnet/testnet interactions
- Node.js >= 16.x for frontend development (if applicable)

## 🛠 Installation & Setup

### 1. Clone the Repository
```bash
git clone repo
cd repo
```

### 2. Initialize Clarinet Project
```bash
clarinet new conectcredit
cd conectcredit
```

### 3. Add the Contract
Copy the `conectcredit.clar` file to the `contracts/` directory.

### 4. Configure Clarinet.toml
```toml
[project]
name = "conectcredit"
authors = ["Your Name <your.email@domain.com>"]
description = "Peer-to-peer lending on Stacks blockchain"

[contracts.conectcredit]
path = "contracts/conectcredit.clar"
```

## Testing

### Run Contract Tests
```bash
clarinet test
```

### Check Contract Syntax
```bash
clarinet check
```

### Interactive Console Testing
```bash
clarinet console
```

Example console commands:
```clarity
;; Create a loan request
(contract-call? .conectcredit create-loan-request u1000000 u1500 u144 u500000)

;; Fund a loan
(contract-call? .conectcredit fund-loan u1)

;; Check loan details
(contract-call? .conectcredit get-loan u1)

;; Repay loan
(contract-call? .conectcredit repay-loan u1)
```

## Usage Guide

### For Borrowers

#### 1. Create Loan Request
```clarity
(contract-call? .conectcredit create-loan-request 
  u1000000    ;; Amount: 1 STX (in microSTX)
  u1500       ;; Interest rate: 15% (in basis points)
  u144        ;; Duration: 144 blocks (~24 hours)
  u500000     ;; Collateral: 0.5 STX (in microSTX)
)
```

#### 2. Wait for Funding
Monitor your loan request status until a lender funds it.

#### 3. Repay Loan
```clarity
(contract-call? .conectcredit repay-loan u1)
```

### For Lenders

#### 1. Browse Available Loans
Use read-only functions to find suitable loan requests.

#### 2. Fund a Loan
```clarity
(contract-call? .conectcredit fund-loan u1)
```

#### 3. Monitor Repayment
Track loan due dates and claim collateral if needed.

#### 4. Claim Collateral (if defaulted)
```clarity
(contract-call? .conectcredit claim-collateral u1)
```

## Configuration

### Platform Settings
- **Platform Fee**: 2.5% (250 basis points) - adjustable by contract owner
- **Maximum Interest Rate**: 20% (2000 basis points) - adjustable by contract owner
- **Minimum Loan Amount**: No minimum (but must be > 0)
- **Collateral Requirement**: Required for all loans

### Interest Rate Calculation
Interest rates are specified in basis points:
- 1000 basis points = 10%
- 1500 basis points = 15%
- 2000 basis points = 20% (maximum)

### Duration Settings
Loan duration is specified in Stacks blocks:
- 144 blocks ≈ 24 hours
- 1008 blocks ≈ 1 week
- 4320 blocks ≈ 1 month

## Security Features

- **Collateral Protection**: All loans require upfront collateral
- **Access Control**: Only authorized users can perform specific actions
- **Input Validation**: Comprehensive parameter validation
- **Overflow Protection**: Safe arithmetic operations
- **State Management**: Proper loan state transitions

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | err-owner-only | Action restricted to contract owner |
| u101 | err-not-found | Loan not found |
| u102 | err-unauthorized | User not authorized for action |
| u103 | err-invalid-amount | Invalid amount specified |
| u104 | err-loan-not-active | Loan is not in active state |
| u105 | err-loan-already-funded | Loan has already been funded |
| u106 | err-insufficient-balance | Insufficient balance for operation |
| u107 | err-loan-not-due | Loan payment is not yet due |
| u108 | err-already-repaid | Loan has already been repaid |
| u109 | err-invalid-interest-rate | Interest rate exceeds maximum |
| u110 | err-invalid-duration | Invalid loan duration |

## Future Enhancements

- [ ] Multi-asset collateral support
- [ ] Partial loan repayments
- [ ] Loan extensions and modifications
- [ ] Advanced reputation algorithms
- [ ] Integration with DeFi protocols
- [ ] Mobile app development
- [ ] Governance token implementation


## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request