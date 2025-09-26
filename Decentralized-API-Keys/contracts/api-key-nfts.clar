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