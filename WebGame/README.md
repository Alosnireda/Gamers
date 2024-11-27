# Tiered Community Membership NFT Smart Contract

This smart contract implements a sophisticated membership NFT system with dynamic tier upgrades, staking mechanisms, and community contribution tracking. Built for the Stacks blockchain using Clarity, it's designed to manage a gaming guild's membership system with multiple tiers and evolving benefits.

## Features

### Membership Tiers
- **Bronze**: Entry-level membership
  - 1x voting power
  - Basic community access
  - Minting cost: 100 STX

- **Silver**: Intermediate membership
  - 2x voting power
  - Requires: 1,000 STX stake for 3 months
  - Additional benefits unlock

- **Gold**: Advanced membership
  - 3x voting power
  - Requires: 2,500 STX stake for 6 months
  - Enhanced community privileges

- **Platinum**: Elite membership
  - 5x voting power
  - Requires: 5,000 STX stake for 12 months
  - Maximum benefits and governance rights

### Core Functionalities

#### 1. Membership Management
- NFT minting with unique token IDs
- Tier-based access control
- Token transfers with preserved history
- Ownership tracking

#### 2. Staking System
- STX token staking mechanism
- Time-locked staking periods
- Automated tier upgrade eligibility checking
- Stake amount verification

#### 3. Contribution Tracking
- Event organization (5 events for badge)
- Tournament participation (3 wins for champion status)
- Community referrals (10 referrals for builder status)
- Content creation (20 pieces for creator badge)

#### 4. Dynamic Traits
- Automatic trait updates based on contributions
- Special badges for community achievements
- Permanent record of accomplishments
- Transferable status markers

## Technical Implementation

### Contract Functions

#### Membership Operations
```clarity
(define-public (mint))
- Purpose: Mint new Bronze tier membership
- Cost: 100 STX
- Returns: Token ID
```

```clarity
(define-public (transfer (token-id uint) (recipient principal)))
- Purpose: Transfer membership to new owner
- Preserves: Tier level and traits
- Requires: Sender ownership
```

#### Staking and Upgrades
```clarity
(define-public (stake (amount uint) (duration uint)))
- Purpose: Stake STX for tier upgrade
- Parameters: Stake amount and duration
- Returns: Success/failure
```

```clarity
(define-public (upgrade-tier (token-id uint)))
- Purpose: Attempt tier upgrade
- Checks: Stake amount and duration
- Updates: Membership tier
```

#### Contribution Management
```clarity
(define-public (record-contribution (token-id uint) (contribution-type (string-ascii 20))))
- Purpose: Record member contributions
- Types: "event", "tournament", "referral", "content"
- Updates: Contribution counters and traits
```

### Read-Only Functions
```clarity
(define-read-only (get-token-tier (token-id uint)))
(define-read-only (get-token-traits (token-id uint)))
(define-read-only (get-token-uri (token-id uint)))
(define-read-only (get-owner (token-id uint)))
(define-read-only (get-voting-power (token-id uint)))
```

## Error Codes
- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized operation attempt
- `ERR-INVALID-TIER (u101)`: Invalid tier specification
- `ERR-INSUFFICIENT-FUNDS (u102)`: Inadequate STX for operation
- `ERR-ALREADY-MINTED (u103)`: Token ID already exists
- `ERR-INSUFFICIENT-STAKE (u104)`: Stake amount below requirement
- `ERR-LOCK-PERIOD-NOT-MET (u105)`: Staking period not completed

## Usage Examples

### Minting a New Membership
```clarity
;; Mint new Bronze membership
(contract-call? .membership-nft mint)
```

### Staking for Upgrade
```clarity
;; Stake 1000 STX for 3 months (4320 blocks)
(contract-call? .membership-nft stake u1000000000 u4320)
```

### Recording Contributions
```clarity
;; Record event organization
(contract-call? .membership-nft record-contribution u1 "event")
```

## Security Considerations
1. Ownership verification on all sensitive operations
2. Stake amount and duration validations
3. Protected upgrade mechanics
4. Secure trait update system
5. Transfer restrictions and verifications

## Development Notes
- Contract requires initialization of tier requirements and voting power multipliers
- IPFS URI base must be set for token metadata
- All amounts are in micro-STX (1 STX = 1,000,000 micro-STX)
- Block heights are used for time calculations (approximately 1 block = 10 minutes)

## Testing
Recommended test scenarios:
1. Membership minting and transfer
2. Staking and tier upgrades
3. Contribution recording and trait updates
4. Voting power calculations
5. Error condition handling

## Future Improvements
1. Integration with external reward systems
2. Enhanced governance mechanisms
3. Additional tier benefits
4. Dynamic requirement adjustments
5. Community reward distribution system