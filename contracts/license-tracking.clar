;; License Tracking Contract
;; Monitors professional authorizations

(define-data-var admin principal tx-sender)

;; License structure
(define-map licenses
  { provider-id: (string-ascii 64), license-id: (string-ascii 64) }
  {
    license-type: (string-ascii 100),
    issuing-authority: (string-ascii 100),
    issue-date: uint,
    expiration-date: uint,
    status: (string-ascii 20),
    last-verified: uint
  }
)

;; Add a new license
(define-public (add-license
    (provider-id (string-ascii 64))
    (license-id (string-ascii 64))
    (license-type (string-ascii 100))
    (issuing-authority (string-ascii 100))
    (issue-date uint)
    (expiration-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? licenses { provider-id: provider-id, license-id: license-id })) (err u100))

    (map-set licenses
      { provider-id: provider-id, license-id: license-id }
      {
        license-type: license-type,
        issuing-authority: issuing-authority,
        issue-date: issue-date,
        expiration-date: expiration-date,
        status: "active",
        last-verified: block-height
      }
    )
    (ok true)
  )
)

;; Update license status
(define-public (update-license-status
    (provider-id (string-ascii 64))
    (license-id (string-ascii 64))
    (status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? licenses { provider-id: provider-id, license-id: license-id })) (err u404))

    (let ((license (unwrap-panic (map-get? licenses { provider-id: provider-id, license-id: license-id }))))
      (map-set licenses
        { provider-id: provider-id, license-id: license-id }
        {
          license-type: (get license-type license),
          issuing-authority: (get issuing-authority license),
          issue-date: (get issue-date license),
          expiration-date: (get expiration-date license),
          status: status,
          last-verified: block-height
        }
      )
    )
    (ok true)
  )
)

;; Get license information
(define-read-only (get-license (provider-id (string-ascii 64)) (license-id (string-ascii 64)))
  (map-get? licenses { provider-id: provider-id, license-id: license-id })
)

;; Check if license is expired
(define-read-only (is-license-expired (provider-id (string-ascii 64)) (license-id (string-ascii 64)))
  (let ((license (unwrap-panic (map-get? licenses { provider-id: provider-id, license-id: license-id }))))
    (> block-height (get expiration-date license))
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
