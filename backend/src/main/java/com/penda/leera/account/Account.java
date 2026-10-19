package com.penda.leera.account;

import java.time.Instant;
import java.util.UUID;

/**
 * A person, known by their Apple ID.
 *
 * @param appleSubject Apple's stable, opaque id for this person in this app
 * @param plusUntil Leera Plus until then; null on the free plan
 */
public record Account(UUID id, String appleSubject, Instant createdAt, Instant plusUntil) {

    public boolean isPlus(Instant now) {
        return plusUntil != null && now.isBefore(plusUntil);
    }
}
