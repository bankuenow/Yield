;; Stacking Rewards Optimizer
;; A smart contract to help users optimize their Stacking rewards with auto-compounding

(define-data-var minimum-stack-amount uint u50000)
(define-data-var stacking-period uint u10)
(define-data-var total-stacked uint u0)

;; Data maps to track user stakes and rewards
(define-map user-stakes 
    principal 
    {
        amount: uint,
        start-block: uint,
        end-block: uint,
        auto-compound: bool
    }
)

(define-map user-rewards
    principal
    {
        pending-rewards: uint,
        total-claimed: uint,
        last-claim-block: uint
    }
)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-NO-ACTIVE-STAKE (err u102))
(define-constant ERR-STAKE-IN-PROGRESS (err u103))
(define-constant ERR-BELOW-MINIMUM (err u104))

;; Read-only functions
(define-read-only (get-user-stake (user principal))
    (map-get? user-stakes user)
)

(define-read-only (get-user-rewards (user principal))
    (map-get? user-rewards user)
)

(define-read-only (calculate-rewards (amount uint) (blocks uint))
    ;; Simplified reward calculation: 10% APY
    (/ (* amount blocks) u1000)
)

;; Public functions
(define-public (stake-tokens (amount uint) (auto-compound bool))
    (let (
        (sender tx-sender)
        (current-block block-height)
    )
        (asserts! (>= amount (var-get minimum-stack-amount)) ERR-BELOW-MINIMUM)
        (asserts! (is-none (map-get? user-stakes sender)) ERR-STAKE-IN-PROGRESS)
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        
        (map-set user-stakes sender {
            amount: amount,
            start-block: current-block,
            end-block: (+ current-block (var-get stacking-period)),
            auto-compound: auto-compound
        })
        
        (var-set total-stacked (+ (var-get total-stacked) amount))
        (ok true)
    )
)

(define-public (claim-rewards)
    (let (
        (sender tx-sender)
        (stake (unwrap! (map-get? user-stakes sender) ERR-NO-ACTIVE-STAKE))
        (current-block block-height)
        (rewards-data (default-to 
            {pending-rewards: u0, total-claimed: u0, last-claim-block: current-block}
            (map-get? user-rewards sender)))
    )
        (let (
            (blocks-passed (- current-block (get last-claim-block rewards-data)))
            (new-rewards (calculate-rewards (get amount stake) blocks-passed))
        )
            (if (get auto-compound stake)
                ;; Auto-compound: add rewards to stake
                (begin
                    (map-set user-stakes sender (merge stake {amount: (+ (get amount stake) new-rewards)}))
                    (ok new-rewards)
                )
                ;; Regular claim: transfer rewards to user
                (begin
                    (try! (as-contract (stx-transfer? new-rewards (as-contract tx-sender) sender)))
                    (map-set user-rewards sender {
                        pending-rewards: u0,
                        total-claimed: (+ (get total-claimed rewards-data) new-rewards),
                        last-claim-block: current-block
                    })
                    (ok new-rewards)
                )
            )
        )
    )
)

(define-public (unstake)
    (let (
        (sender tx-sender)
        (stake (unwrap! (map-get? user-stakes sender) ERR-NO-ACTIVE-STAKE))
    )
        (asserts! (>= block-height (get end-block stake)) ERR-STAKE-IN-PROGRESS)
        
        ;; Claim any remaining rewards first
        (try! (claim-rewards))
        
        ;; Return staked amount
        (try! (as-contract (stx-transfer? (get amount stake) (as-contract tx-sender) sender)))
        
        ;; Clear stake data
        (map-delete user-stakes sender)
        (var-set total-stacked (- (var-get total-stacked) (get amount stake)))
        
        (ok true)
    )
)