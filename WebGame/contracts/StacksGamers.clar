;; Tiered Community Membership NFT Contract
;; StacksGamers Guild Implementation

;; Constants for tiers
(define-constant BRONZE u1)
(define-constant SILVER u2)
(define-constant GOLD u3)
(define-constant PLATINUM u4)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-TIER (err u101))
(define-constant ERR-INSUFFICIENT-FUNDS (err u102))
(define-constant ERR-ALREADY-MINTED (err u103))
(define-constant ERR-INSUFFICIENT-STAKE (err u104))
(define-constant ERR-LOCK-PERIOD-NOT-MET (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant ERR-INVALID-DURATION (err u107))
(define-constant ERR-INVALID-TOKEN-ID (err u108))

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var total-supply uint u0)
(define-data-var uri-base (string-ascii 256) "ipfs://QmXyz...")

;; Data maps
(define-map token-tiers { token-id: uint } { tier: uint })
(define-map token-owners { token-id: uint } { owner: principal })
(define-map stakes 
    { staker: principal } 
    { amount: uint, start-block: uint, duration: uint })
(define-map contributions 
    { user: principal } 
    { events: uint, tournaments: uint, referrals: uint, content: uint })
(define-map tier-requirements 
    { tier: uint }
    { stake-amount: uint, lock-period: uint })
(define-map voting-power
    { tier: uint }
    { multiplier: uint })
(define-map traits
    { token-id: uint }
    { 
        event-organizer: bool,
        tournament-champion: bool,
        community-builder: bool,
        content-creator: bool
    })

;; Initialize contract
(begin
    ;; Set tier requirements
    (map-set tier-requirements { tier: SILVER }
        { stake-amount: u1000000000, lock-period: u4320 }) ;; 1000 STX, 3 months
    (map-set tier-requirements { tier: GOLD }
        { stake-amount: u2500000000, lock-period: u8640 }) ;; 2500 STX, 6 months
    (map-set tier-requirements { tier: PLATINUM }
        { stake-amount: u5000000000, lock-period: u17280 }) ;; 5000 STX, 12 months
    
    ;; Set voting power multipliers
    (map-set voting-power { tier: BRONZE } { multiplier: u1 })
    (map-set voting-power { tier: SILVER } { multiplier: u2 })
    (map-set voting-power { tier: GOLD } { multiplier: u3 })
    (map-set voting-power { tier: PLATINUM } { multiplier: u5 })
)

;; SFT Mint function - Initial Bronze membership
(define-public (mint)
    (let
        (
            (token-id (+ (var-get total-supply) u1))
            (caller tx-sender)
        )
        (asserts! (is-none (get owner (map-get? token-owners { token-id: token-id }))) ERR-ALREADY-MINTED)
        (try! (stx-transfer? u100000000 caller (var-get contract-owner))) ;; 100 STX mint fee
        (map-set token-owners { token-id: token-id } { owner: caller })
        (map-set token-tiers { token-id: token-id } { tier: BRONZE })
        (map-set traits { token-id: token-id }
            { 
                event-organizer: false,
                tournament-champion: false,
                community-builder: false,
                content-creator: false
            }
        )
        (var-set total-supply token-id)
        (ok token-id)
    )
)

;; Stake STX for tier upgrade
(define-public (stake (amount uint) (duration uint))
    (let
        (
            (caller tx-sender)
        )
        ;; Validate amount is greater than minimum stake required for Silver
        (asserts! (>= amount (get stake-amount (unwrap! (map-get? tier-requirements { tier: SILVER }) ERR-INVALID-TIER))) ERR-INVALID-AMOUNT)
        ;; Validate duration is at least minimum lock period
        (asserts! (>= duration (get lock-period (unwrap! (map-get? tier-requirements { tier: SILVER }) ERR-INVALID-TIER))) ERR-INVALID-DURATION)
        
        (try! (stx-transfer? amount caller (as-contract tx-sender)))
        (map-set stakes { staker: caller }
            { 
                amount: amount,
                start-block: block-height,
                duration: duration
            }
        )
        (ok true)
    )
)

;; Upgrade tier based on stake and time
(define-public (upgrade-tier (token-id uint))
    (let
        (
            (caller tx-sender)
        )
        ;; Validate token exists
        (asserts! (<= token-id (var-get total-supply)) ERR-INVALID-TOKEN-ID)
        (let
            (
                (current-tier (unwrap! (get tier (map-get? token-tiers { token-id: token-id })) ERR-INVALID-TIER))
                (stake-info (unwrap! (map-get? stakes { staker: caller }) ERR-INSUFFICIENT-STAKE))
                (next-tier (+ current-tier u1))
                (tier-req (unwrap! (map-get? tier-requirements { tier: next-tier }) ERR-INVALID-TIER))
            )
            (asserts! (>= (get amount stake-info) (get stake-amount tier-req)) ERR-INSUFFICIENT-STAKE)
            (asserts! (>= (- block-height (get start-block stake-info)) (get lock-period tier-req)) ERR-LOCK-PERIOD-NOT-MET)
            (map-set token-tiers { token-id: token-id } { tier: next-tier })
            (ok true)
        )
    )
)

;; Record community contributions
(define-public (record-contribution (token-id uint) (contribution-type (string-ascii 20)))
    (let
        (
            (caller tx-sender)
        )
        ;; Validate token exists
        (asserts! (<= token-id (var-get total-supply)) ERR-INVALID-TOKEN-ID)
        (let 
            (
                (current-contributions (default-to 
                    { events: u0, tournaments: u0, referrals: u0, content: u0 }
                    (map-get? contributions { user: caller })))
            )
            (asserts! (is-eq caller (get owner (unwrap! (map-get? token-owners { token-id: token-id }) ERR-NOT-AUTHORIZED))) ERR-NOT-AUTHORIZED)
            
            ;; Validate contribution type
            (asserts! (or 
                (is-eq contribution-type "event")
                (is-eq contribution-type "tournament")
                (is-eq contribution-type "referral")
                (is-eq contribution-type "content")) 
                ERR-INVALID-TIER)

            ;; Update contributions based on type
            (if (is-eq contribution-type "event")
                (map-set contributions { user: caller }
                    (merge current-contributions { events: (+ (get events current-contributions) u1) }))
                (if (is-eq contribution-type "tournament")
                    (map-set contributions { user: caller }
                        (merge current-contributions { tournaments: (+ (get tournaments current-contributions) u1) }))
                    (if (is-eq contribution-type "referral")
                        (map-set contributions { user: caller }
                            (merge current-contributions { referrals: (+ (get referrals current-contributions) u1) }))
                        (map-set contributions { user: caller }
                            (merge current-contributions { content: (+ (get content current-contributions) u1) })))))
            
            (try! (check-and-update-traits token-id))
            (ok true)
        )
    )
)

;; Check and update traits based on contributions
(define-private (check-and-update-traits (token-id uint))
    (let
        (
            (caller tx-sender)
            (current-contributions (unwrap! (map-get? contributions { user: caller }) ERR-NOT-AUTHORIZED))
            (current-traits (unwrap! (map-get? traits { token-id: token-id }) ERR-NOT-AUTHORIZED))
        )
        (map-set traits { token-id: token-id }
            {
                event-organizer: (or (get event-organizer current-traits) (>= (get events current-contributions) u5)),
                tournament-champion: (or (get tournament-champion current-traits) (>= (get tournaments current-contributions) u3)),
                community-builder: (or (get community-builder current-traits) (>= (get referrals current-contributions) u10)),
                content-creator: (or (get content-creator current-traits) (>= (get content current-contributions) u20))
            }
        )
        (ok true)
    )
)

;; Get voting power for a token
(define-public (get-voting-power (token-id uint))
    (let
        (
            (tier (unwrap! (get tier (map-get? token-tiers { token-id: token-id })) ERR-INVALID-TIER))
            (power (unwrap! (map-get? voting-power { tier: tier }) ERR-INVALID-TIER))
        )
        (ok (get multiplier power))
    )
)

;; Transfer token
(define-public (transfer (token-id uint) (recipient principal))
    (let
        (
            (caller tx-sender)
        )
        ;; Validate token exists
        (asserts! (<= token-id (var-get total-supply)) ERR-INVALID-TOKEN-ID)
        ;; Validate recipient is not the zero address
        (asserts! (not (is-eq recipient (as-contract tx-sender))) ERR-NOT-AUTHORIZED)
        
        (let
            (
                (owner-data (unwrap! (map-get? token-owners { token-id: token-id }) ERR-NOT-AUTHORIZED))
            )
            (asserts! (is-eq caller (get owner owner-data)) ERR-NOT-AUTHORIZED)
            (map-set token-owners { token-id: token-id } { owner: recipient })
            (ok true)
        )
    )
)

;; Read-only functions
(define-read-only (get-token-tier (token-id uint))
    (get tier (map-get? token-tiers { token-id: token-id }))
)

(define-read-only (get-token-traits (token-id uint))
    (map-get? traits { token-id: token-id })
)

(define-read-only (get-token-uri (token-id uint))
    (let
        (
            (id-string (concat 
                        (concat 
                            (concat
                                (concat
                                    (concat
                                        (concat
                                            (concat "" 
                                                (if (>= token-id u1000000000) (int-to-ascii (/ token-id u1000000000)) ""))
                                            (if (>= token-id u100000000) (int-to-ascii (/ (mod token-id u1000000000) u100000000)) ""))
                                        (if (>= token-id u10000000) (int-to-ascii (/ (mod token-id u100000000) u10000000)) ""))
                                    (if (>= token-id u1000000) (int-to-ascii (/ (mod token-id u10000000) u1000000)) ""))
                                (if (>= token-id u100000) (int-to-ascii (/ (mod token-id u1000000) u100000)) ""))
                            (if (>= token-id u10000) (int-to-ascii (/ (mod token-id u100000) u10000)) ""))
                        (if (>= token-id u1000) (int-to-ascii (/ (mod token-id u10000) u1000)) ""))
            )
        )
        (some (concat (concat (var-get uri-base) id-string)
            (concat
                (concat
                    (if (>= token-id u100) (int-to-ascii (/ (mod token-id u1000) u100)) "")
                    (if (>= token-id u10) (int-to-ascii (/ (mod token-id u100) u10)) ""))
                (int-to-ascii (mod token-id u10))
            )
        ))
    )
)

(define-read-only (get-owner (token-id uint))
    (get owner (map-get? token-owners { token-id: token-id }))
)