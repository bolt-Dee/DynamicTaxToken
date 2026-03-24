;; Contract Name: DynamicTaxToken
;; A fungible token with a dynamic transfer tax (stable vs volatile mode)
;; - Admin sets treasury and toggles volatility mode
;; - Users should use `transfer-taxed` to move tokens (applies current tax)
;; - Admin can mint/burn (for issuance control)
;; Notes: SIP-010 ft-* helpers (ft-transfer?, ft-mint?, ft-burn?, ft-get-balance) are used.

(define-fungible-token DYN-TOKEN)

;; Admin / Treasury
(define-data-var admin principal tx-sender)
(define-data-var treasury principal tx-sender)

;; Tax parameters (numerator / denominator)
(define-constant TAX_STABLE_NUM u1)    ;; 0.1% = 1 / 1000
(define-constant TAX_STABLE_DEN u1000)
(define-constant TAX_VOLATILE_NUM u10) ;; 1% = 10 / 1000
(define-constant TAX_VOLATILE_DEN u1000)

;; Mode: true = VOLATILE (higher tax), false = STABLE (lower tax)
(define-data-var volatile-mode bool false)

;; Errors
(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-TRANSFER-FAIL (err u101))
(define-constant ERR-MINT-FAIL (err u102))
(define-constant ERR-BURN-FAIL (err u103))
(define-constant ERR-ZERO-AMOUNT (err u104))

;; Read-only: view current tax rate as numerator/denominator tuple
(define-read-only (current-tax)
  (if (var-get volatile-mode)
      (tuple (num TAX_VOLATILE_NUM) (den TAX_VOLATILE_DEN))
      (tuple (num TAX_STABLE_NUM) (den TAX_STABLE_DEN))))

;; Admin: set treasury address
(define-public (set-treasury (to principal))
  (if (is-eq tx-sender (var-get admin))
      (begin (var-set treasury to) (ok true))
      ERR-NOT-ADMIN))

;; Admin: toggle volatility mode
(define-public (set-volatile-mode (mode bool))
  (if (is-eq tx-sender (var-get admin))
      (begin (var-set volatile-mode mode) (ok true))
      ERR-NOT-ADMIN))

;; Admin: mint tokens to an address
(define-public (admin-mint (to principal) (amount uint))
  (if (is-eq tx-sender (var-get admin))
      (if (> amount u0)
          (let ((res (ft-mint? DYN-TOKEN amount to)))
            (match res
              mint-success (ok true)
              mint-failure ERR-MINT-FAIL))
          (err u106)) ;; Invalid amount
      ERR-NOT-ADMIN))

;; Admin: burn tokens from an address
(define-public (admin-burn (from principal) (amount uint))
  (if (is-eq tx-sender (var-get admin))
      (if (> amount u0)
          (let ((res (ft-burn? DYN-TOKEN amount from)))
            (match res
              burn-success (ok true)
              burn-failure ERR-BURN-FAIL))
          (err u107)) ;; Invalid amount
      ERR-NOT-ADMIN))

;; Helper: compute fee = floor(amount * num / den)

;; Helper: compute fee = floor(amount * num / den)
(define-read-only (compute-fee (amount uint))
  (let ((mode (var-get volatile-mode)))
    (let ((num (if mode TAX_VOLATILE_NUM TAX_STABLE_NUM))
          (den (if mode TAX_VOLATILE_DEN TAX_STABLE_DEN)))
      (/ (* amount num) den))))

;; Primary transfer that applies tax. Caller can be sender or contract acting on behalf.
(define-public (transfer-taxed (amount uint) (sender principal) (recipient principal))
  (begin
    (if (<= amount u0)
        (err u104)
        (let ((fee (compute-fee amount))
              (net (let ((f (compute-fee amount))) (- amount f))))
          ;; send fee to treasury first (if fee > 0)
          (if (> fee u0)
              (match (ft-transfer? DYN-TOKEN fee sender (var-get treasury))
                fee-success
                  (match (ft-transfer? DYN-TOKEN net sender recipient)
                    net-success (ok (tuple (transferred net) (fee fee)))
                    net-failure ERR-TRANSFER-FAIL)
                fee-failure ERR-TRANSFER-FAIL)
              ;; no fee case
              (match (ft-transfer? DYN-TOKEN net sender recipient)
                only-success (ok (tuple (transferred net) (fee u0)))
                only-failure ERR-TRANSFER-FAIL))))))

;; Read-only helpers
(define-read-only (balance-of (who principal))
  (ft-get-balance DYN-TOKEN who))

(define-read-only (is-volatile)
  (var-get volatile-mode))