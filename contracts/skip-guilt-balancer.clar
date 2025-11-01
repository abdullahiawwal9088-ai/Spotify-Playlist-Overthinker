;; Skip Guilt Balancer Contract
;; Calculates ethical skip rates for artists under 10k monthly listeners

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-listener-count (err u201))
(define-constant err-invalid-skip-rate (err u202))
(define-constant err-artist-not-found (err u203))
(define-constant err-unauthorized (err u204))
(define-constant err-already-registered (err u205))
(define-constant err-invalid-percentage (err u206))

;; Emerging artist threshold: 10,000 monthly listeners
(define-constant emerging-artist-threshold u10000)

;; Maximum acceptable skip rate for emerging artists (40%)
(define-constant max-ethical-skip-rate u40)

;; Minimum plays before calculating skip guilt (10 plays)
(define-constant min-plays-for-calculation u10)

;; Data Variables
(define-data-var total-artists-registered uint u0)
(define-data-var global-support-multiplier uint u100)

;; Data Maps

;; Artist registry
(define-map artists
  { artist-id: uint }
  {
    artist-name: (string-ascii 100),
    monthly-listeners: uint,
    registered-by: principal,
    registered-at: uint,
    is-emerging: bool,
    is-active: bool
  }
)

;; Artist name to ID lookup
(define-map artist-lookup
  { artist-name: (string-ascii 100) }
  { artist-id: uint }
)

;; Skip tracking for each artist
(define-map skip-data
  { artist-id: uint }
  {
    total-plays: uint,
    total-skips: uint,
    current-skip-rate: uint,
    ethical-skip-rate: uint,
    last-updated: uint,
    skip-guilt-score: uint
  }
)

;; User skip behavior per artist
(define-map user-skip-tracking
  { user: principal, artist-id: uint }
  {
    plays: uint,
    skips: uint,
    user-skip-rate: uint,
    guilt-points: uint
  }
)

;; Artist support metrics
(define-map artist-support
  { artist-id: uint }
  {
    total-supporters: uint,
    total-guilt-free-plays: uint,
    support-score: uint
  }
)

;; Private Functions

;; Calculate skip rate percentage
(define-private (calculate-skip-rate (total-plays uint) (total-skips uint))
  (if (is-eq total-plays u0)
    u0
    (/ (* total-skips u100) total-plays)
  )
)

;; Calculate ethical skip rate based on listener count
(define-private (calculate-ethical-rate (listener-count uint))
  (if (>= listener-count emerging-artist-threshold)
    max-ethical-skip-rate
    (let
      (
        (ratio (/ (* listener-count u100) emerging-artist-threshold))
        (adjusted-rate (/ (* ratio max-ethical-skip-rate) u100))
      )
      (if (< adjusted-rate u5) u5 adjusted-rate)
    )
  )
)

;; Calculate guilt score based on skip rate vs ethical rate
(define-private (calculate-guilt-score (actual-rate uint) (ethical-rate uint))
  (if (<= actual-rate ethical-rate)
    u0
    (let
      (
        (excess (- actual-rate ethical-rate))
        (guilt (* excess u2))
      )
      (if (> guilt u100) u100 guilt)
    )
  )
)

;; Check if artist is emerging (under threshold)
(define-private (is-emerging-artist (listener-count uint))
  (< listener-count emerging-artist-threshold)
)

;; Public Functions

;; Register a new artist
(define-public (register-artist (artist-name (string-ascii 100)) (monthly-listeners uint))
  (let
    (
      (artist-id (var-get total-artists-registered))
      (is-emerging (is-emerging-artist monthly-listeners))
      (ethical-rate (calculate-ethical-rate monthly-listeners))
    )
    (asserts! (is-none (map-get? artist-lookup { artist-name: artist-name })) err-already-registered)
    
    ;; Register artist
    (map-set artists
      { artist-id: artist-id }
      {
        artist-name: artist-name,
        monthly-listeners: monthly-listeners,
        registered-by: tx-sender,
        registered-at: stacks-block-height,
        is-emerging: is-emerging,
        is-active: true
      }
    )
    
    ;; Create lookup
    (map-set artist-lookup
      { artist-name: artist-name }
      { artist-id: artist-id }
    )
    
    ;; Initialize skip data
    (map-set skip-data
      { artist-id: artist-id }
      {
        total-plays: u0,
        total-skips: u0,
        current-skip-rate: u0,
        ethical-skip-rate: ethical-rate,
        last-updated: stacks-block-height,
        skip-guilt-score: u0
      }
    )
    
    ;; Initialize support metrics
    (map-set artist-support
      { artist-id: artist-id }
      {
        total-supporters: u0,
        total-guilt-free-plays: u0,
        support-score: u100
      }
    )
    
    ;; Increment counter
    (var-set total-artists-registered (+ artist-id u1))
    
    (ok artist-id)
  )
)

;; Record a play (no skip)
(define-public (record-play (artist-id uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-artist-not-found))
      (skip-info (unwrap! (map-get? skip-data { artist-id: artist-id }) err-artist-not-found))
      (user-data (default-to 
                   { plays: u0, skips: u0, user-skip-rate: u0, guilt-points: u0 }
                   (map-get? user-skip-tracking { user: tx-sender, artist-id: artist-id })))
      (support (unwrap! (map-get? artist-support { artist-id: artist-id }) err-artist-not-found))
    )
    (asserts! (get is-active artist) err-artist-not-found)
    
    (let
      (
        (new-total-plays (+ (get total-plays skip-info) u1))
        (new-skip-rate (calculate-skip-rate new-total-plays (get total-skips skip-info)))
        (new-guilt-score (calculate-guilt-score new-skip-rate (get ethical-skip-rate skip-info)))
        (new-user-plays (+ (get plays user-data) u1))
        (new-user-skip-rate (calculate-skip-rate new-user-plays (get skips user-data)))
      )
      ;; Update skip data
      (map-set skip-data
        { artist-id: artist-id }
        (merge skip-info 
          { 
            total-plays: new-total-plays,
            current-skip-rate: new-skip-rate,
            skip-guilt-score: new-guilt-score,
            last-updated: stacks-block-height
          }
        )
      )
      
      ;; Update user tracking
      (map-set user-skip-tracking
        { user: tx-sender, artist-id: artist-id }
        (merge user-data
          {
            plays: new-user-plays,
            user-skip-rate: new-user-skip-rate
          }
        )
      )
      
      ;; Update support metrics
      (map-set artist-support
        { artist-id: artist-id }
        (merge support
          {
            total-guilt-free-plays: (+ (get total-guilt-free-plays support) u1)
          }
        )
      )
      
      (ok { new-skip-rate: new-skip-rate, guilt-score: new-guilt-score })
    )
  )
)

;; Record a skip
(define-public (record-skip (artist-id uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-artist-not-found))
      (skip-info (unwrap! (map-get? skip-data { artist-id: artist-id }) err-artist-not-found))
      (user-data (default-to 
                   { plays: u0, skips: u0, user-skip-rate: u0, guilt-points: u0 }
                   (map-get? user-skip-tracking { user: tx-sender, artist-id: artist-id })))
    )
    (asserts! (get is-active artist) err-artist-not-found)
    
    (let
      (
        (new-total-plays (+ (get total-plays skip-info) u1))
        (new-total-skips (+ (get total-skips skip-info) u1))
        (new-skip-rate (calculate-skip-rate new-total-plays new-total-skips))
        (new-guilt-score (calculate-guilt-score new-skip-rate (get ethical-skip-rate skip-info)))
        (new-user-plays (+ (get plays user-data) u1))
        (new-user-skips (+ (get skips user-data) u1))
        (new-user-skip-rate (calculate-skip-rate new-user-plays new-user-skips))
        (new-guilt-points (calculate-guilt-score new-user-skip-rate (get ethical-skip-rate skip-info)))
      )
      ;; Update skip data
      (map-set skip-data
        { artist-id: artist-id }
        (merge skip-info 
          { 
            total-plays: new-total-plays,
            total-skips: new-total-skips,
            current-skip-rate: new-skip-rate,
            skip-guilt-score: new-guilt-score,
            last-updated: stacks-block-height
          }
        )
      )
      
      ;; Update user tracking
      (map-set user-skip-tracking
        { user: tx-sender, artist-id: artist-id }
        (merge user-data
          {
            plays: new-user-plays,
            skips: new-user-skips,
            user-skip-rate: new-user-skip-rate,
            guilt-points: new-guilt-points
          }
        )
      )
      
      (ok { new-skip-rate: new-skip-rate, guilt-score: new-guilt-score, user-guilt: new-guilt-points })
    )
  )
)

;; Update artist listener count
(define-public (update-listener-count (artist-id uint) (new-listener-count uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-artist-not-found))
      (skip-info (unwrap! (map-get? skip-data { artist-id: artist-id }) err-artist-not-found))
    )
    (asserts! (is-eq tx-sender (get registered-by artist)) err-unauthorized)
    
    (let
      (
        (new-ethical-rate (calculate-ethical-rate new-listener-count))
        (is-emerging (is-emerging-artist new-listener-count))
      )
      ;; Update artist
      (map-set artists
        { artist-id: artist-id }
        (merge artist 
          { 
            monthly-listeners: new-listener-count,
            is-emerging: is-emerging
          }
        )
      )
      
      ;; Update skip data with new ethical rate
      (map-set skip-data
        { artist-id: artist-id }
        (merge skip-info { ethical-skip-rate: new-ethical-rate })
      )
      
      (ok true)
    )
  )
)

;; Deactivate artist
(define-public (deactivate-artist (artist-id uint))
  (let
    (
      (artist (unwrap! (map-get? artists { artist-id: artist-id }) err-artist-not-found))
    )
    (asserts! (is-eq tx-sender (get registered-by artist)) err-unauthorized)
    
    (map-set artists
      { artist-id: artist-id }
      (merge artist { is-active: false })
    )
    
    (ok true)
  )
)

;; Read-only Functions

;; Get artist details
(define-read-only (get-artist (artist-id uint))
  (map-get? artists { artist-id: artist-id })
)

;; Get artist by name
(define-read-only (get-artist-by-name (artist-name (string-ascii 100)))
  (match (map-get? artist-lookup { artist-name: artist-name })
    lookup (map-get? artists { artist-id: (get artist-id lookup) })
    none
  )
)

;; Get skip data for artist
(define-read-only (get-skip-data (artist-id uint))
  (map-get? skip-data { artist-id: artist-id })
)

;; Get user skip tracking
(define-read-only (get-user-stats (user principal) (artist-id uint))
  (map-get? user-skip-tracking { user: user, artist-id: artist-id })
)

;; Get artist support metrics
(define-read-only (get-support-metrics (artist-id uint))
  (map-get? artist-support { artist-id: artist-id })
)

;; Check if user is within ethical skip rate
(define-read-only (is-user-ethical (user principal) (artist-id uint))
  (match (map-get? user-skip-tracking { user: user, artist-id: artist-id })
    user-data
      (match (map-get? skip-data { artist-id: artist-id })
        skip-info
          (ok (<= (get user-skip-rate user-data) (get ethical-skip-rate skip-info)))
        err-artist-not-found
      )
    (ok true)
  )
)

;; Get total registered artists
(define-read-only (get-total-artists)
  (var-get total-artists-registered)
)

;; Calculate recommended max skips for user
(define-read-only (get-recommended-max-skips (artist-id uint) (user principal))
  (match (map-get? skip-data { artist-id: artist-id })
    skip-info
      (match (map-get? user-skip-tracking { user: user, artist-id: artist-id })
        user-data
          (let
            (
              (ethical-rate (get ethical-skip-rate skip-info))
              (current-plays (get plays user-data))
              (max-skips (/ (* current-plays ethical-rate) u100))
            )
            (ok max-skips)
          )
        (ok u0)
      )
    err-artist-not-found
  )
)

;; title: skip-guilt-balancer
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

