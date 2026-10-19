package com.penda.leera.account;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class QuotaWindowTest {

    @Test
    void theFreeWeekStartsOnMondayAtMidnightUtc() {
        // Sunday 25 October 2026, late evening: still the week of Monday the 19th.
        assertThat(QuotaService.startOfWeek(Instant.parse("2026-10-25T23:59:59Z")))
                .isEqualTo(Instant.parse("2026-10-19T00:00:00Z"));
        assertThat(QuotaService.startOfWeek(Instant.parse("2026-10-19T00:00:00Z")))
                .isEqualTo(Instant.parse("2026-10-19T00:00:00Z"));
        assertThat(QuotaService.startOfWeek(Instant.parse("2026-10-26T00:00:00Z")))
                .isEqualTo(Instant.parse("2026-10-26T00:00:00Z"));
    }

    @Test
    void thePlusDayStartsAtMidnightUtc() {
        assertThat(QuotaService.startOfDay(Instant.parse("2026-10-21T17:30:00Z")))
                .isEqualTo(Instant.parse("2026-10-21T00:00:00Z"));
    }
}
