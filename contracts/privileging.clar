;; Privileging Contract
;; Records approved medical procedures

(define-data-var admin principal tx-sender)

;; Privilege structure
(define-map privileges
  { provider-id: (string-ascii 64), privilege-id: (string-ascii 64) }
  {
    procedure: (string-ascii 100),
    facility: (string-ascii 100),
    granted-date: uint,
    expiration-date: uint,
    status: (string-ascii 20),
    granted-by: principal
  }
)

;; Grant a privilege
(define-public (grant-privilege
    (provider-id (string-ascii 64))
    (privilege-id (string-ascii 64))
    (procedure (string-ascii 100))
    (facility (string-ascii 100))
    (expiration-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? privileges { provider-id: provider-id, privilege-id: privilege-id })) (err u100))

    (map-set privileges
      { provider-id: provider-id, privilege-id: privilege-id }
      {
        procedure: procedure,
        facility: facility,
        granted-date: block-height,
        expiration-date: expiration-date,
        status: "active",
        granted-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Revoke a privilege
(define-public (revoke-privilege
    (provider-id (string-ascii 64))
    (privilege-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? privileges { provider-id: provider-id, privilege-id: privilege-id })) (err u404))

    (let ((privilege (unwrap-panic (map-get? privileges { provider-id: provider-id, privilege-id: privilege-id }))))
      (map-set privileges
        { provider-id: provider-id, privilege-id: privilege-id }
        {
          procedure: (get procedure privilege),
          facility: (get facility privilege),
          granted-date: (get granted-date privilege),
          expiration-date: (get expiration-date privilege),
          status: "revoked",
          granted-by: (get granted-by privilege)
        }
      )
    )
    (ok true)
  )
)

;; Get privilege information
(define-read-only (get-privilege (provider-id (string-ascii 64)) (privilege-id (string-ascii 64)))
  (map-get? privileges { provider-id: provider-id, privilege-id: privilege-id })
)

;; Check if privilege is valid
(define-read-only (is-privilege-valid (provider-id (string-ascii 64)) (privilege-id (string-ascii 64)))
  (let ((privilege (unwrap-panic (map-get? privileges { provider-id: provider-id, privilege-id: privilege-id }))))
    (and
      (is-eq (get status privilege) "active")
      (< block-height (get expiration-date privilege))
    )
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
