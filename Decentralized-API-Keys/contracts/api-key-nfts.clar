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

(define-public (register-api-service 
  (name (string-ascii 64))
  (description (string-ascii 256))
  (price-per-call uint)
  (max-calls-per-period uint)
  (period-duration uint)
  (category (string-ascii 32))
  (api-version (string-ascii 16))
  (rate-limit-per-second uint)
  (whitelisted-only bool))
  (let ((caller tx-sender)
        (service-id (var-get next-service-id)))
    (asserts! (>= price-per-call min-service-price) err-invalid-parameters)
    (asserts! (> max-calls-per-period u0) err-invalid-parameters)
    (asserts! (> period-duration u0) err-invalid-parameters)
    
    (map-set api-services service-id {
      provider: caller,
      name: name,
      description: description,
      price-per-call: price-per-call,
      max-calls-per-period: max-calls-per-period,
      period-duration: period-duration,
      active: true,
      created-at: block-height,
      category: category,
      api-version: api-version,
      rate-limit-per-second: rate-limit-per-second,
      whitelisted-only: whitelisted-only,
      total-revenue: u0,
      total-keys-sold: u0
    })
    
    (var-set next-service-id (+ service-id u1))
    (var-set total-services (+ (var-get total-services) u1))
    (ok service-id)))

(define-public (create-subscription-tier
  (service-id uint)
  (tier-id uint)
  (name (string-ascii 32))
  (max-calls uint)
  (price-multiplier uint)
  (additional-features (string-ascii 128)))
  (let ((service (unwrap! (map-get? api-services service-id) err-not-found)))
    (asserts! (is-eq tx-sender (get provider service)) err-unauthorized)
    (asserts! (not (is-some (map-get? subscription-tiers {service-id: service-id, tier-id: tier-id}))) err-already-exists)
    
    (ok (map-set subscription-tiers {service-id: service-id, tier-id: tier-id} {
      name: name,
      max-calls: max-calls,
      price-multiplier: price-multiplier,
      additional-features: additional-features
    }))))

(define-public (add-to-whitelist (service-id uint) (user principal))
  (let ((service (unwrap! (map-get? api-services service-id) err-not-found)))
    (asserts! (is-eq tx-sender (get provider service)) err-unauthorized)
    (asserts! (not (default-to false (map-get? service-whitelist {service-id: service-id, user: user}))) err-already-whitelisted)
    
    (ok (map-set service-whitelist {service-id: service-id, user: user} true))))

(define-public (purchase-api-key (service-id uint) (subscription-tier uint) (enable-auto-renewal bool))
  (let ((caller tx-sender)
        (service (unwrap! (map-get? api-services service-id) err-not-found))
        (key-id (var-get next-key-id))
        (tier (map-get? subscription-tiers {service-id: service-id, tier-id: subscription-tier})))
    
    (asserts! (get active service) err-service-inactive)
    
    ;; Check whitelist if required
    (if (get whitelisted-only service)
      (asserts! (default-to false (map-get? service-whitelist {service-id: service-id, user: caller})) err-not-whitelisted)
      true)
    
    (let ((calls-allowed (if (is-some tier)
                          (get max-calls (unwrap-panic tier))
                          (get max-calls-per-period service)))
          (price-multiplier (if (is-some tier)
                            (get price-multiplier (unwrap-panic tier))
                            u100))
          (total-cost (/ (* (* (get price-per-call service) calls-allowed) price-multiplier) u100))
          (platform-fee (/ (* total-cost platform-fee-rate) u10000)))
      
      (asserts! (>= (stx-get-balance caller) total-cost) err-insufficient-payment)
      
      (try! (stx-transfer? platform-fee caller contract-owner))
      (try! (stx-transfer? (- total-cost platform-fee) caller (get provider service)))
      (try! (nft-mint? api-key-nft key-id caller))
      
      (map-set api-keys key-id {
        service-id: service-id,
        owner: caller,
        calls-remaining: calls-allowed,
        period-start: block-height,
        period-end: (+ block-height (get period-duration service)),
        total-calls-made: u0,
        created-at: block-height,
        active: true,
        subscription-tier: subscription-tier,
        auto-renewal: enable-auto-renewal,
        last-used: u0,
        refund-eligible-until: (+ block-height max-refund-period)
      })
      
      ;; Update service statistics
      (map-set api-services service-id
        (merge service {
          total-revenue: (+ (get total-revenue service) (- total-cost platform-fee)),
          total-keys-sold: (+ (get total-keys-sold service) u1)
        }))
      
      ;; Update user reputation
      (update-user-reputation caller service-id u0)
      
      (var-set next-key-id (+ key-id u1))
      (var-set total-active-keys (+ (var-get total-active-keys) u1))
      (var-set platform-revenue (+ (var-get platform-revenue) platform-fee))
      (ok key-id))))
