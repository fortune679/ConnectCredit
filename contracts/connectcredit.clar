;; ConectCredit - Peer-to-Peer Lending Smart Contract
;; Built on Stacks Blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-loan-not-active (err u104))
(define-constant err-loan-already-funded (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-loan-not-due (err u107))
(define-constant err-already-repaid (err u108))
(define-constant err-invalid-interest-rate (err u109))
(define-constant err-invalid-duration (err u110))

;; Data Variables
(define-data-var loan-id-nonce uint u0)
(define-data-var platform-fee uint u250) ;; 2.5% in basis points (250/10000)
(define-data-var max-interest-rate uint u2000) ;; 20% max interest rate in basis points

;; Data Maps
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    lender: (optional principal),
    amount: uint,
    interest-rate: uint, ;; in basis points (e.g., 1000 = 10%)
    duration: uint, ;; in blocks
    collateral: uint,
    created-at: uint,
    funded-at: (optional uint),
    due-date: (optional uint),
    repaid: bool,
    defaulted: bool
  }
)

(define-map user-stats
  { user: principal }
  {
    total-borrowed: uint,
    total-lent: uint,
    active-loans: uint,
    completed-loans: uint,
    reputation-score: uint
  }
)

;; Read-only functions
(define-read-only (get-loan (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-user-stats (user principal))
  (default-to 
    { total-borrowed: u0, total-lent: u0, active-loans: u0, completed-loans: u0, reputation-score: u100 }
    (map-get? user-stats { user: user })
  )
)

(define-read-only (get-loan-id-nonce)
  (var-get loan-id-nonce)
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (calculate-total-repayment (amount uint) (interest-rate uint))
  (let ((interest (/ (* amount interest-rate) u10000)))
    (+ amount interest)
  )
)

(define-read-only (is-loan-due (loan-id uint))
  (match (get-loan loan-id)
    loan-data 
      (match (get due-date loan-data)
        due-date (>= block-height due-date)
        false
      )
    false
  )
)

;; Private functions
(define-private (update-user-stats (user principal) (amount uint) (action (string-ascii 10)))
  (let ((current-stats (get-user-stats user)))
    (if (is-eq action "borrow")
      (map-set user-stats 
        { user: user }
        (merge current-stats {
          total-borrowed: (+ (get total-borrowed current-stats) amount),
          active-loans: (+ (get active-loans current-stats) u1)
        })
      )
      (if (is-eq action "lend")
        (map-set user-stats 
          { user: user }
          (merge current-stats {
            total-lent: (+ (get total-lent current-stats) amount),
            active-loans: (+ (get active-loans current-stats) u1)
          })
        )
        (if (is-eq action "repay")
          (map-set user-stats 
            { user: user }
            (merge current-stats {
              active-loans: (if (> (get active-loans current-stats) u0) 
                             (- (get active-loans current-stats) u1) 
                             u0),
              completed-loans: (+ (get completed-loans current-stats) u1),
              reputation-score: (if (< (get reputation-score current-stats) u200)
                                 (+ (get reputation-score current-stats) u5)
                                 u200)
            })
          )
          true
        )
      )
    )
  )
)

;; Public functions
(define-public (create-loan-request (amount uint) (interest-rate uint) (duration uint) (collateral uint))
  (let ((loan-id (+ (var-get loan-id-nonce) u1)))
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (<= interest-rate (var-get max-interest-rate)) err-invalid-interest-rate)
    (asserts! (> duration u0) err-invalid-duration)
    
    (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
    
    (map-set loans
      { loan-id: loan-id }
      {
        borrower: tx-sender,
        lender: none,
        amount: amount,
        interest-rate: interest-rate,
        duration: duration,
        collateral: collateral,
        created-at: block-height,
        funded-at: none,
        due-date: none,
        repaid: false,
        defaulted: false
      }
    )
    
    (var-set loan-id-nonce loan-id)
    (update-user-stats tx-sender amount "borrow")
    
    (ok loan-id)
  )
)

(define-public (fund-loan (loan-id uint))
  (match (get-loan loan-id)
    loan-data
      (begin
        (asserts! (is-none (get lender loan-data)) err-loan-already-funded)
        (asserts! (not (is-eq tx-sender (get borrower loan-data))) err-unauthorized)
        
        (let ((amount (get amount loan-data))
              (platform-fee-amount (/ (* amount (var-get platform-fee)) u10000))
              (net-amount (- amount platform-fee-amount))
              (due-date (+ block-height (get duration loan-data))))
          
          (try! (stx-transfer? amount tx-sender (get borrower loan-data)))
          (try! (stx-transfer? platform-fee-amount tx-sender contract-owner))
          
          (map-set loans
            { loan-id: loan-id }
            (merge loan-data {
              lender: (some tx-sender),
              funded-at: (some block-height),
              due-date: (some due-date)
            })
          )
          
          (update-user-stats tx-sender amount "lend")
          (ok true)
        )
      )
    err-not-found
  )
)

(define-public (repay-loan (loan-id uint))
  (match (get-loan loan-id)
    loan-data
      (begin
        (asserts! (is-eq tx-sender (get borrower loan-data)) err-unauthorized)
        (asserts! (is-some (get lender loan-data)) err-loan-not-active)
        (asserts! (not (get repaid loan-data)) err-already-repaid)
        
        (let ((total-repayment (calculate-total-repayment (get amount loan-data) (get interest-rate loan-data)))
              (lender (unwrap! (get lender loan-data) err-not-found)))
          
          (try! (stx-transfer? total-repayment tx-sender lender))
          (try! (as-contract (stx-transfer? (get collateral loan-data) tx-sender (get borrower loan-data))))
          
          (map-set loans
            { loan-id: loan-id }
            (merge loan-data { repaid: true })
          )
          
          (update-user-stats tx-sender (get amount loan-data) "repay")
          (ok true)
        )
      )
    err-not-found
  )
)

(define-public (claim-collateral (loan-id uint))
  (match (get-loan loan-id)
    loan-data
      (begin
        (asserts! (is-some (get lender loan-data)) err-loan-not-active)
        (asserts! (is-eq tx-sender (unwrap! (get lender loan-data) err-unauthorized)) err-unauthorized)
        (asserts! (not (get repaid loan-data)) err-already-repaid)
        (asserts! (is-loan-due loan-id) err-loan-not-due)
        
        (try! (as-contract (stx-transfer? (get collateral loan-data) tx-sender tx-sender)))
        
        (map-set loans
          { loan-id: loan-id }
          (merge loan-data { defaulted: true })
        )
        
        (ok true)
      )
    err-not-found
  )
)

;; Admin functions
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-amount) ;; max 10%
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (set-max-interest-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set max-interest-rate new-rate)
    (ok true)
  )
)