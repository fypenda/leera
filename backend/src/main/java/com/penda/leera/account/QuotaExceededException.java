package com.penda.leera.account;

/** The account has used every correction of its quota for now. */
public class QuotaExceededException extends RuntimeException {

    private final QuotaService.Status status;

    public QuotaExceededException(QuotaService.Status status) {
        super("Quota used up: " + status.used() + " of " + status.limit());
        this.status = status;
    }

    public QuotaService.Status status() {
        return status;
    }
}
