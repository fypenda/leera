package com.penda.leera.account;

import com.penda.leera.auth.AuthException;
import com.penda.leera.config.LeeraProperties;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Counts corrections against each account's quota.
 *
 * <p>A correction is reserved before the model is asked, and released if the model fails: what
 * did not reach the person does not count. The free plan counts per week (from Monday, UTC),
 * Leera Plus per day (UTC).
 *
 * <p>Development accounts ({@code dev:<name>}, see {@link DevSignInController}) have no limit, as
 * long as signing in without Apple is on: they exist to try the app over and over.
 */
@Service
public class QuotaService {

    public enum Plan {
        FREE,
        PLUS,
        /** A development account: corrections are counted, never refused. */
        DEV
    }

    /** Where an account stands: {@code used} of {@code limit} until {@code resetsAt}. */
    public record Status(Plan plan, int used, int limit, Instant resetsAt) {

        public boolean exhausted() {
            return used >= limit;
        }
    }

    /** A correction counted before it is made, to give back if it fails. */
    public record Reservation(UUID id) {}

    private final JdbcClient jdbc;
    private final AccountRepository accounts;
    private final Clock clock;
    private final LeeraProperties.Quota quota;
    private final boolean devSignIn;

    public QuotaService(
            JdbcClient jdbc, AccountRepository accounts, Clock clock, LeeraProperties properties) {
        this.jdbc = jdbc;
        this.accounts = accounts;
        this.clock = clock;
        this.quota = properties.quota();
        this.devSignIn = properties.auth().devSignIn();
    }

    public Status status(UUID accountId) {
        return statusOf(accounts.findById(accountId).orElseThrow(AuthException::unknownAccount));
    }

    /** Counts one correction, or refuses with {@link QuotaExceededException}. */
    @Transactional
    public Reservation reserve(UUID accountId) {
        Account account = accounts.lockById(accountId).orElseThrow(AuthException::unknownAccount);
        Status status = statusOf(account);
        if (status.exhausted()) {
            throw new QuotaExceededException(status);
        }
        var reservation = new Reservation(UUID.randomUUID());
        jdbc.sql(
                        "INSERT INTO corrections (id, account_id, created_at) "
                                + "VALUES (:id, :account, :createdAt)")
                .param("id", reservation.id())
                .param("account", accountId)
                .param("createdAt", AccountRepository.utc(clock.instant()))
                .update();
        return reservation;
    }

    /** Gives back a correction that could not be made. */
    public void release(Reservation reservation) {
        jdbc.sql("DELETE FROM corrections WHERE id = :id").param("id", reservation.id()).update();
    }

    Status statusOf(Account account) {
        Instant now = clock.instant();
        if (devSignIn && account.appleSubject().startsWith(DevSignInController.SUBJECT_PREFIX)) {
            Instant start = startOfWeek(now);
            Instant end = start.plus(Duration.ofDays(7));
            return new Status(Plan.DEV, countBetween(account, start, end), Integer.MAX_VALUE, end);
        }
        boolean plus = account.isPlus(now);
        Instant start = plus ? startOfDay(now) : startOfWeek(now);
        Instant end = start.plus(plus ? Duration.ofDays(1) : Duration.ofDays(7));
        return new Status(
                plus ? Plan.PLUS : Plan.FREE,
                countBetween(account, start, end),
                plus ? quota.plusPerDay() : quota.freePerWeek(),
                end);
    }

    private int countBetween(Account account, Instant start, Instant end) {
        Long used =
                jdbc.sql(
                                "SELECT COUNT(*) FROM corrections WHERE account_id = :account "
                                        + "AND created_at >= :start AND created_at < :end")
                        .param("account", account.id())
                        .param("start", AccountRepository.utc(start))
                        .param("end", AccountRepository.utc(end))
                        .query(Long.class)
                        .single();
        return used.intValue();
    }

    static Instant startOfDay(Instant now) {
        return now.atZone(ZoneOffset.UTC).toLocalDate().atStartOfDay(ZoneOffset.UTC).toInstant();
    }

    static Instant startOfWeek(Instant now) {
        LocalDate monday =
                now.atZone(ZoneOffset.UTC)
                        .toLocalDate()
                        .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        return monday.atStartOfDay(ZoneOffset.UTC).toInstant();
    }
}
