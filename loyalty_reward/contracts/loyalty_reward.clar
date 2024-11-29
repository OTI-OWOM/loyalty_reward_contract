
;; title: loyalty_reward
(define-map balances {address: principal} uint)
(define-map rewards {address: principal} uint)
(define-map reward-history {address: principal, timestamp: uint} uint)
(define-map reward-expiration {address: principal, timestamp: uint} uint)

(define-map redemption-history {address: principal, timestamp: uint} uint)
(define-map user-tier {address: principal} (string-ascii 10))


;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_INVALID_AMOUNT (err u1))
(define-constant ERR_INSUFFICIENT_REWARDS (err u2))
(define-constant ERR_REWARDS_EXPIRED (err u3))
(define-constant ERR_UNAUTHORIZED (err u4))
(define-constant ERR_INVALID_USER (err u5))

;; Reward Tier Constants
(define-constant SILVER_THRESHOLD u100)
(define-constant GOLD_THRESHOLD u500)
(define-constant REWARD_EXPIRATION_PERIOD u604800) ;; 1 week in seconds

;; Read-only Functions
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances {address: user})))

(define-read-only (get-rewards (user principal))
  (default-to u0 (map-get? rewards {address: user})))



;; Private Helper Functions
(define-private (is-valid-amount (amount uint))
  (> amount u0))

(define-private (calculate-reward-tier (balance uint))
  (if (>= balance GOLD_THRESHOLD)
      "gold"
      (if (>= balance SILVER_THRESHOLD)
          "silver"
          "bronze")))

;; Public Functions
(define-public (add-balance (amount uint))
  (begin
    (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
    (map-set balances {address: tx-sender} 
             (+ (get-balance tx-sender) amount))
     ;; Automatically accumulate rewards based on balance
    (let ((current-rewards (get-rewards tx-sender)))
      (map-set rewards {address: tx-sender} (+ current-rewards amount)))
    (ok true)))


(define-map last-claim-block {address: principal} uint)

(define-map last-claim-time {address: principal} uint)

;; Define a constant for block time approximation (10 seconds per block)
(define-constant BLOCK_TIME_SECONDS u10)

;; Store the deployment block as a reference point
(define-data-var deployment-block uint u0)

(define-constant ERR_ALREADY_INITIALIZED (err u1))


(define-public (transfer-rewards (to principal) (amount uint))
  (begin
    (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
    (asserts! (is-valid-amount (get-rewards tx-sender)) ERR_INSUFFICIENT_REWARDS)
    (asserts! (is-valid-amount (get-balance to)) ERR_INVALID_USER)
    (let ((current-rewards (get-rewards tx-sender)))
      (asserts! (>= current-rewards amount) ERR_INSUFFICIENT_REWARDS)
      ;; Deduct from sender's rewards and add to recipient's rewards
      (map-set rewards {address: tx-sender} (- current-rewards amount))
      (map-set rewards {address: to} (+ (get-rewards to) amount))
      (ok true))))

;; Public Function: Update User Tier
(define-public (update-user-tier)
  (let ((balance (get-balance tx-sender)))
    (let ((tier (calculate-reward-tier balance)))
      (map-set user-tier {address: tx-sender} tier)
      (ok tier))))

;; Ownership transfer
(define-data-var contract-owner principal tx-sender)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)))

;; Owner check helper
(define-private (is-contract-owner (sender principal))
  (is-eq sender (var-get contract-owner)))


;; Emergency withdrawal for contract owner
(define-public (emergency-withdraw)
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (let ((total-balance (get-balance tx-sender)))
      (map-set balances {address: tx-sender} u0)
      (map-set rewards {address: tx-sender} u0)
      (ok total-balance)))) 