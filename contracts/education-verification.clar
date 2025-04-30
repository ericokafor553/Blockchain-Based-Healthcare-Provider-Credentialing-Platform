;; Education Verification Contract
;; Validates medical training credentials

(define-data-var admin principal tx-sender)

;; Education credential structure
(define-map education-credentials
  { provider-id: (string-ascii 64), credential-id: (string-ascii 64) }
  {
    institution: (string-ascii 100),
    degree: (string-ascii 100),
    year-completed: uint,
    verified: bool,
    verified-by: principal,
    verified-at: uint
  }
)

;; Add education credential
(define-public (add-credential
    (provider-id (string-ascii 64))
    (credential-id (string-ascii 64))
    (institution (string-ascii 100))
    (degree (string-ascii 100))
    (year-completed uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? education-credentials { provider-id: provider-id, credential-id: credential-id })) (err u100))

    (map-set education-credentials
      { provider-id: provider-id, credential-id: credential-id }
      {
        institution: institution,
        degree: degree,
        year-completed: year-completed,
        verified: false,
        verified-by: tx-sender,
        verified-at: u0
      }
    )
    (ok true)
  )
)

;; Verify education credential
(define-public (verify-credential
    (provider-id (string-ascii 64))
    (credential-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? education-credentials { provider-id: provider-id, credential-id: credential-id })) (err u404))

    (let ((credential (unwrap-panic (map-get? education-credentials { provider-id: provider-id, credential-id: credential-id }))))
      (map-set education-credentials
        { provider-id: provider-id, credential-id: credential-id }
        {
          institution: (get institution credential),
          degree: (get degree credential),
          year-completed: (get year-completed credential),
          verified: true,
          verified-by: tx-sender,
          verified-at: block-height
        }
      )
    )
    (ok true)
  )
)

;; Get education credential
(define-read-only (get-credential (provider-id (string-ascii 64)) (credential-id (string-ascii 64)))
  (map-get? education-credentials { provider-id: provider-id, credential-id: credential-id })
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
