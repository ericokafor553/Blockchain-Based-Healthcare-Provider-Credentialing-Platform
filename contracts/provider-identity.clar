;; Provider Identity Contract
;; Manages healthcare practitioner profiles

(define-data-var admin principal tx-sender)

;; Provider data structure
(define-map providers
  { provider-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    specialty: (string-ascii 100),
    contact: (string-ascii 100),
    active: bool,
    created-at: uint,
    updated-at: uint
  }
)

;; Create a new provider profile
(define-public (register-provider
    (provider-id (string-ascii 64))
    (name (string-ascii 100))
    (specialty (string-ascii 100))
    (contact (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) (err u100))

    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        contact: contact,
        active: true,
        created-at: block-height,
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Update provider information
(define-public (update-provider
    (provider-id (string-ascii 64))
    (name (string-ascii 100))
    (specialty (string-ascii 100))
    (contact (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? providers { provider-id: provider-id })) (err u404))

    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        contact: contact,
        active: true,
        created-at: (get created-at (unwrap-panic (map-get? providers { provider-id: provider-id }))),
        updated-at: block-height
      }
    )
    (ok true)
  )
)

;; Deactivate a provider
(define-public (deactivate-provider (provider-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? providers { provider-id: provider-id })) (err u404))

    (let ((provider (unwrap-panic (map-get? providers { provider-id: provider-id }))))
      (map-set providers
        { provider-id: provider-id }
        {
          name: (get name provider),
          specialty: (get specialty provider),
          contact: (get contact provider),
          active: false,
          created-at: (get created-at provider),
          updated-at: block-height
        }
      )
    )
    (ok true)
  )
)

;; Read provider information
(define-read-only (get-provider (provider-id (string-ascii 64)))
  (map-get? providers { provider-id: provider-id })
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
