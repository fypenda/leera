package com.penda.leera.support;

import com.penda.leera.account.Account;
import com.penda.leera.account.AccountRepository;
import com.penda.leera.auth.SessionTokens;
import java.util.UUID;

/** Accounts and sessions for tests, without going through Apple. */
public final class TestSessions {

    private TestSessions() {}

    /** A new account, with an Apple id no other test uses. */
    public static Account newAccount(AccountRepository accounts) {
        return accounts.findOrCreateByAppleSubject("test." + UUID.randomUUID());
    }

    /** The {@code Authorization} header of a session for {@code account}. */
    public static String bearer(SessionTokens sessions, Account account) {
        return "Bearer " + sessions.issue(account.id()).token();
    }
}
