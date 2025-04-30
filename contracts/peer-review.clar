;; Peer Review Contract
;; Manages quality assessment by colleagues

(define-data-var admin principal tx-sender)

;; Peer review structure
(define-map peer-reviews
  { provider-id: (string-ascii 64), review-id: (string-ascii 64) }
  {
    reviewer-id: (string-ascii 64),
    review-date: uint,
    category: (string-ascii 50),
    rating: uint,
    comments: (string-ascii 500),
    verified: bool
  }
)

;; Submit a peer review
(define-public (submit-review
    (provider-id (string-ascii 64))
    (review-id (string-ascii 64))
    (reviewer-id (string-ascii 64))
    (category (string-ascii 50))
    (rating uint)
    (comments (string-ascii 500)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? peer-reviews { provider-id: provider-id, review-id: review-id })) (err u100))
    (asserts! (<= rating u5) (err u101)) ;; Rating must be between 0 and 5

    (map-set peer-reviews
      { provider-id: provider-id, review-id: review-id }
      {
        reviewer-id: reviewer-id,
        review-date: block-height,
        category: category,
        rating: rating,
        comments: comments,
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify a peer review
(define-public (verify-review
    (provider-id (string-ascii 64))
    (review-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? peer-reviews { provider-id: provider-id, review-id: review-id })) (err u404))

    (let ((review (unwrap-panic (map-get? peer-reviews { provider-id: provider-id, review-id: review-id }))))
      (map-set peer-reviews
        { provider-id: provider-id, review-id: review-id }
        {
          reviewer-id: (get reviewer-id review),
          review-date: (get review-date review),
          category: (get category review),
          rating: (get rating review),
          comments: (get comments review),
          verified: true
        }
      )
    )
    (ok true)
  )
)

;; Get peer review
(define-read-only (get-review (provider-id (string-ascii 64)) (review-id (string-ascii 64)))
  (map-get? peer-reviews { provider-id: provider-id, review-id: review-id })
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
