;; Vibe Mismatch Detector Contract
;; Flags songs that violate the declared playlist mood by more than 18%

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-mood (err u101))
(define-constant err-invalid-threshold (err u102))
(define-constant err-playlist-not-found (err u103))
(define-constant err-song-not-found (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-unauthorized (err u106))

;; Mood value range: 0-100
(define-constant min-mood-value u0)
(define-constant max-mood-value u100)

;; Default mismatch threshold: 18%
(define-constant default-mismatch-threshold u18)

;; Data Variables
(define-data-var global-mismatch-threshold uint u18)

;; Data Maps

;; Playlist registry
(define-map playlists
  { playlist-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    declared-mood: uint,
    mismatch-threshold: uint,
    created-at: uint,
    is-active: bool
  }
)

;; Song registry within playlists
(define-map songs
  { playlist-id: uint, song-id: uint }
  {
    song-name: (string-ascii 200),
    mood-value: uint,
    is-flagged: bool,
    deviation-percentage: uint,
    added-at: uint,
    added-by: principal
  }
)

;; Playlist counters
(define-map playlist-counter
  { owner: principal }
  { count: uint }
)

;; Song counters per playlist
(define-map song-counter
  { playlist-id: uint }
  { count: uint }
)

;; Mismatch statistics
(define-map mismatch-stats
  { playlist-id: uint }
  {
    total-songs: uint,
    flagged-songs: uint,
    last-updated: uint
  }
)

;; Private Functions

;; Calculate deviation percentage between two mood values
(define-private (calculate-deviation (base-mood uint) (song-mood uint))
  (let
    (
      (diff (if (> base-mood song-mood)
                (- base-mood song-mood)
                (- song-mood base-mood)))
    )
    ;; Return percentage deviation
    (/ (* diff u100) base-mood)
  )
)

;; Check if mood value is valid (0-100)
(define-private (is-valid-mood (mood uint))
  (and (>= mood min-mood-value) (<= mood max-mood-value))
)

;; Get next playlist ID for owner
(define-private (get-next-playlist-id (owner principal))
  (let
    (
      (current-count (default-to { count: u0 } 
                      (map-get? playlist-counter { owner: owner })))
    )
    (get count current-count)
  )
)

;; Get next song ID for playlist
(define-private (get-next-song-id (playlist-id uint))
  (let
    (
      (current-count (default-to { count: u0 } 
                      (map-get? song-counter { playlist-id: playlist-id })))
    )
    (get count current-count)
  )
)

;; Public Functions

;; Create a new playlist with declared mood
(define-public (create-playlist (name (string-ascii 100)) (declared-mood uint))
  (let
    (
      (playlist-id (get-next-playlist-id tx-sender))
      (threshold (var-get global-mismatch-threshold))
    )
    (asserts! (is-valid-mood declared-mood) err-invalid-mood)
    (asserts! (> declared-mood u0) err-invalid-mood)
    
    ;; Create playlist
    (map-set playlists
      { playlist-id: playlist-id }
      {
        owner: tx-sender,
        name: name,
        declared-mood: declared-mood,
        mismatch-threshold: threshold,
        created-at: stacks-block-height,
        is-active: true
      }
    )
    
    ;; Update counter
    (map-set playlist-counter
      { owner: tx-sender }
      { count: (+ playlist-id u1) }
    )
    
    ;; Initialize stats
    (map-set mismatch-stats
      { playlist-id: playlist-id }
      {
        total-songs: u0,
        flagged-songs: u0,
        last-updated: stacks-block-height
      }
    )
    
    (ok playlist-id)
  )
)

;; Add song to playlist and check for mismatch
(define-public (add-song (playlist-id uint) (song-name (string-ascii 200)) (mood-value uint))
  (let
    (
      (playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-playlist-not-found))
      (song-id (get-next-song-id playlist-id))
      (declared-mood (get declared-mood playlist))
      (threshold (get mismatch-threshold playlist))
      (deviation (calculate-deviation declared-mood mood-value))
      (is-flagged (> deviation threshold))
      (stats (unwrap! (map-get? mismatch-stats { playlist-id: playlist-id }) err-playlist-not-found))
    )
    (asserts! (is-valid-mood mood-value) err-invalid-mood)
    (asserts! (get is-active playlist) err-playlist-not-found)
    
    ;; Add song
    (map-set songs
      { playlist-id: playlist-id, song-id: song-id }
      {
        song-name: song-name,
        mood-value: mood-value,
        is-flagged: is-flagged,
        deviation-percentage: deviation,
        added-at: stacks-block-height,
        added-by: tx-sender
      }
    )
    
    ;; Update song counter
    (map-set song-counter
      { playlist-id: playlist-id }
      { count: (+ song-id u1) }
    )
    
    ;; Update stats
    (map-set mismatch-stats
      { playlist-id: playlist-id }
      {
        total-songs: (+ (get total-songs stats) u1),
        flagged-songs: (if is-flagged 
                          (+ (get flagged-songs stats) u1)
                          (get flagged-songs stats)),
        last-updated: stacks-block-height
      }
    )
    
    (ok { song-id: song-id, is-flagged: is-flagged, deviation: deviation })
  )
)

;; Update playlist mismatch threshold
(define-public (update-threshold (playlist-id uint) (new-threshold uint))
  (let
    (
      (playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-playlist-not-found))
    )
    (asserts! (is-eq tx-sender (get owner playlist)) err-unauthorized)
    (asserts! (<= new-threshold u100) err-invalid-threshold)
    
    (map-set playlists
      { playlist-id: playlist-id }
      (merge playlist { mismatch-threshold: new-threshold })
    )
    
    (ok true)
  )
)

;; Deactivate playlist
(define-public (deactivate-playlist (playlist-id uint))
  (let
    (
      (playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-playlist-not-found))
    )
    (asserts! (is-eq tx-sender (get owner playlist)) err-unauthorized)
    
    (map-set playlists
      { playlist-id: playlist-id }
      (merge playlist { is-active: false })
    )
    
    (ok true)
  )
)

;; Update global mismatch threshold (owner only)
(define-public (set-global-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-threshold u100) err-invalid-threshold)
    (var-set global-mismatch-threshold new-threshold)
    (ok true)
  )
)

;; Read-only Functions

;; Get playlist details
(define-read-only (get-playlist (playlist-id uint))
  (map-get? playlists { playlist-id: playlist-id })
)

;; Get song details
(define-read-only (get-song (playlist-id uint) (song-id uint))
  (map-get? songs { playlist-id: playlist-id, song-id: song-id })
)

;; Get mismatch statistics
(define-read-only (get-stats (playlist-id uint))
  (map-get? mismatch-stats { playlist-id: playlist-id })
)

;; Get global threshold
(define-read-only (get-global-threshold)
  (var-get global-mismatch-threshold)
)

;; Check if song would be flagged
(define-read-only (check-song-compatibility (playlist-id uint) (mood-value uint))
  (match (map-get? playlists { playlist-id: playlist-id })
    playlist
      (let
        (
          (declared-mood (get declared-mood playlist))
          (threshold (get mismatch-threshold playlist))
          (deviation (calculate-deviation declared-mood mood-value))
        )
        (ok { would-flag: (> deviation threshold), deviation: deviation })
      )
    err-playlist-not-found
  )
)

;; Get playlist song count
(define-read-only (get-song-count (playlist-id uint))
  (match (map-get? song-counter { playlist-id: playlist-id })
    counter (ok (get count counter))
    (ok u0)
  )
)

;; Calculate mismatch rate for playlist
(define-read-only (get-mismatch-rate (playlist-id uint))
  (match (map-get? mismatch-stats { playlist-id: playlist-id })
    stats
      (let
        (
          (total (get total-songs stats))
          (flagged (get flagged-songs stats))
        )
        (if (is-eq total u0)
          (ok u0)
          (ok (/ (* flagged u100) total))
        )
      )
    err-playlist-not-found
  )
)

;; title: vibe-mismatch-detector
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

