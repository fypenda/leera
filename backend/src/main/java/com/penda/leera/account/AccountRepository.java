package com.penda.leera.account;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/** The accounts table. */
@Repository
public class AccountRepository {

    private static final String COLUMNS = "id, apple_subject, created_at, plus_until";

    private final JdbcClient jdbc;
    private final Clock clock;

    public AccountRepository(JdbcClient jdbc, Clock clock) {
        this.jdbc = jdbc;
        this.clock = clock;
    }

    /**
     * The account of this Apple ID, created the first time it signs in.
     *
     * <p>Two first sign-ins at once both try to create it: the second finds the first's.
     */
    public Account findOrCreateByAppleSubject(String appleSubject) {
        var existing = findByAppleSubject(appleSubject);
        if (existing.isPresent()) {
            return existing.get();
        }
        var account = new Account(UUID.randomUUID(), appleSubject, clock.instant(), null);
        try {
            jdbc.sql(
                            "INSERT INTO accounts (id, apple_subject, created_at) "
                                    + "VALUES (:id, :subject, :createdAt)")
                    .param("id", account.id())
                    .param("subject", appleSubject)
                    .param("createdAt", utc(account.createdAt()))
                    .update();
            return account;
        } catch (DuplicateKeyException e) {
            return findByAppleSubject(appleSubject).orElseThrow();
        }
    }

    public Optional<Account> findById(UUID id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM accounts WHERE id = :id")
                .param("id", id)
                .query(AccountRepository::map)
                .optional();
    }

    public Optional<Account> findByAppleSubject(String appleSubject) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM accounts WHERE apple_subject = :subject")
                .param("subject", appleSubject)
                .query(AccountRepository::map)
                .optional();
    }

    /**
     * The account, locked until the current transaction ends, so that two requests at once
     * cannot both take the last correction of a quota.
     */
    public Optional<Account> lockById(UUID id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM accounts WHERE id = :id FOR UPDATE")
                .param("id", id)
                .query(AccountRepository::map)
                .optional();
    }

    public boolean exists(UUID id) {
        return findById(id).isPresent();
    }

    /** Leera Plus until {@code until}, or the free plan with null. */
    public void setPlusUntil(UUID id, Instant until) {
        jdbc.sql("UPDATE accounts SET plus_until = :until WHERE id = :id")
                .param("until", until == null ? null : utc(until))
                .param("id", id)
                .update();
    }

    /** Deletes the account and, with it, the count of its corrections. */
    public void delete(UUID id) {
        jdbc.sql("DELETE FROM accounts WHERE id = :id").param("id", id).update();
    }

    static OffsetDateTime utc(Instant instant) {
        return OffsetDateTime.ofInstant(instant, ZoneOffset.UTC);
    }

    private static Account map(ResultSet rs, int row) throws SQLException {
        OffsetDateTime plusUntil = rs.getObject("plus_until", OffsetDateTime.class);
        return new Account(
                rs.getObject("id", UUID.class),
                rs.getString("apple_subject"),
                rs.getObject("created_at", OffsetDateTime.class).toInstant(),
                plusUntil == null ? null : plusUntil.toInstant());
    }
}
