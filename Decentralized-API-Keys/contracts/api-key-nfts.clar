;; Decentralized API Keys
;; NFT-based API key management and monetization with advanced features

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-insufficient-payment (err u104))
(define-constant err-usage-exceeded (err u105))
(define-constant err-invalid-parameters (err u106))
(define-constant err-service-inactive (err u107))
(define-constant err-refund-failed (err u108))
(define-constant err-already-whitelisted (err u109))
(define-constant err-not-whitelisted (err u110))
(define-constant err-tier-not-found (err u111))
(define-constant err-subscription-expired (err u112))

(define-constant max-refund-period u144) ;; ~1 day in blocks
(define-constant platform-fee-rate u50) ;; 0.5% in basis points
(define-constant min-service-price u1000) ;; Minimum price per call

(define-non-fungible-token api-key-nft uint)

(define-map api-services
  uint
  {
    provider: principal,
    name: (string-ascii 64),
    description: (string-ascii 256),
    price-per-call: uint,
    max-calls-per-period: uint,
    period-duration: uint,
    active: bool,
    created-at: uint,
    category: (string-ascii 32),
    api-version: (string-ascii 16),
    rate-limit-per-second: uint,
    whitelisted-only: bool,
    total-revenue: uint,
    total-keys-sold: uint
  })

(define-map api-keys
  uint
  {
    service-id: uint,
    owner: principal,
    calls-remaining: uint,
    period-start: uint,
    period-end: uint,
    total-calls-made: uint,
    created-at: uint,
    active: bool,
    subscription-tier: uint,
    auto-renewal: bool,
    last-used: uint,
    refund-eligible-until: uint
  })

(define-map api-usage-logs
  { key-id: uint, log-id: uint }
  {
    timestamp: uint,
    calls-used: uint,
    endpoint: (string-ascii 128),
    response-size: uint,
    success: bool,
    error-code: (optional uint)
  })

(define-map key-usage-counter
  uint
  uint)

(define-map service-whitelist
  { service-id: uint, user: principal }
  bool)

(define-map subscription-tiers
  { service-id: uint, tier-id: uint }
  {
    name: (string-ascii 32),
    max-calls: uint,
    price-multiplier: uint,
    additional-features: (string-ascii 128)
  })

(define-map user-reputation
  principal
  {
    total-api-calls: uint,
    services-used: uint,
    reputation-score: uint,
    violations: uint,
    join-date: uint
  })

(define-map service-analytics
  { service-id: uint, period: uint }
  {
    total-calls: uint,
    unique-users: uint,
    revenue: uint,
    average-response-time: uint
  })

(define-data-var next-service-id uint u1)
(define-data-var next-key-id uint u1)
(define-data-var platform-revenue uint u0)
(define-data-var total-services uint u0)
(define-data-var total-active-keys uint u0)