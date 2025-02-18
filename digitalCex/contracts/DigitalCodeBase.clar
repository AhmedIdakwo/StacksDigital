;; Stage 1: Basic Digital Content Exchange

;; Contract configuration
(define-constant owner-address tx-sender)
(define-constant ERR_UNAUTHORIZED (err u201))
(define-constant ERR_ITEM_UNAVAILABLE (err u202))
(define-constant ERR_DUPLICATE_ITEM (err u203))
(define-constant ERR_INSUFFICIENT_FUNDS (err u204))
(define-constant ERR_PRICE_INVALID (err u205))

;; Storage structures
(define-map content-offerings 
    { item-id: uint }
    {
        owner: principal,
        price-tag: uint,
        content-summary: (string-ascii 256),
        tradeable: bool
    }
)

(define-map content-keys
    { item-id: uint }
    { secure-access-token: (string-ascii 512) }
)

;; State variables
(define-data-var item-counter uint u1)
(define-data-var exchange-fee uint u3) ;; 3% fee

;; Helper functions
(define-private (compute-fee (price uint))
    (/ (* price (var-get exchange-fee)) u100)
)

(define-private (process-payment (from principal) (to principal) (amount uint))
    (stx-transfer? amount from to)
)

;; Core functions
(define-public (register-content (asking-price uint) 
                               (summary (string-ascii 256)) 
                               (access-token (string-ascii 512)))
    (let
        (
            (current-id (var-get item-counter))
        )
        (asserts! (> asking-price u0) ERR_PRICE_INVALID)
        (asserts! (not (is-eq summary "")) ERR_PRICE_INVALID)
        (asserts! (not (is-eq access-token "")) ERR_PRICE_INVALID)
        
        (map-set content-offerings
            { item-id: current-id }
            {
                owner: tx-sender,
                price-tag: asking-price,
                content-summary: summary,
                tradeable: true
            }
        )
        
        (map-set content-keys
            { item-id: current-id }
            { secure-access-token: access-token }
        )
        
        (var-set item-counter (+ current-id u1))
        (ok current-id)
    )
)

(define-public (acquire-content (item-id uint))
    (let
        (
            (item-info (unwrap! (map-get? content-offerings { item-id: item-id }) 
                ERR_ITEM_UNAVAILABLE))
            (total-cost (get price-tag item-info))
            (merchant (get owner item-info))
            (fee-amount (compute-fee total-cost))
            (merchant-share (- total-cost fee-amount))
        )
        (asserts! (get tradeable item-info) ERR_ITEM_UNAVAILABLE)
        
        (try! (process-payment tx-sender merchant merchant-share))
        (try! (process-payment tx-sender owner-address fee-amount))
        (ok true)
    )
)

;; Query functions
(define-read-only (get-content-info (item-id uint))
    (map-get? content-offerings { item-id: item-id })
)

(define-read-only (get-current-fee)
    (var-get exchange-fee)
)
