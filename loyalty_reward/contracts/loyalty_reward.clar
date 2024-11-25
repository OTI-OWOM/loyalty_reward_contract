
;; title: loyalty_reward
(define-map balances {address: principal} uint)
(define-map rewards {address: principal} uint)
(define-map reward-history {address: principal, timestamp: uint} uint)
(define-map reward-expiration {address: principal, timestamp: uint} uint)


;; Constants for reward tiers
(define-constant SILVER_THRESHOLD u100)
(define-constant GOLD_THRESHOLD u500)
