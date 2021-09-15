;; A wallet contract that containes a number of STX tokens
;; After a certain amount of time, the wallet contract will release these tokens
;; to a specific beneficiary specified by the contract delpoyer.

(define-constant contract-deployer tx-sender)

(define-constant err-owner-only (err u100))
(define-constant err-unlock-in-past (err u101))
(define-constant err-no-value (err u102))
(define-constant err-already-locked (err u103))
(define-constant err-beneficiary-only (err u104))
(define-constant err-unlock-height-not-reached (err u105))

(define-data-var beneficiary principal tx-sender)
(define-data-var unlock-height uint u0) ;;when wallet will unlock, block #, anchor blocks on STX take 10mins

(define-public (lock (new-beneficiary principal) (unlock-at uint) (amount uint)) ;;deposits initial amount of STX tokens
    (begin
        (asserts! (is-eq tx-sender contract-deployer) err-owner-only)
        (asserts! (> unlock-at block-height) err-unlock-in-past) ;;unlock-height should be larger than block-height
        (asserts! (> amount u0) err-no-value) ;;amount to be despoited should not be u0
        (asserts! (is-eq (var-get unlock-height) u0) err-already-locked) ;;can only send tokens at block-height of 0
        (var-set beneficiary new-beneficiary)
        (var-set unlock-height unlock-at)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender))) ;;send from sender to contract, try=try expression, if not revert entire func, as-contract allows transactions to be sent from contract
        (ok true)
    )
)

(define-public (claim)
    (begin
        (asserts! (is-eq (var-get beneficiary) tx-sender) err-beneficiary-only)
        (asserts! (>= block-height (var-get unlock-height)) err-unlock-height-not-reached)
        (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender (var-get beneficiary)))
    )
)

;; CHALLENGE give the beneficiary the ability to transfer the right to claim the wallet
;;change address that can the claim the wallet