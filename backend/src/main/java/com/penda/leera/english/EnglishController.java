package com.penda.leera.english;

import com.penda.leera.account.QuotaService;
import com.penda.leera.security.SessionFilter;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/english")
public class EnglishController {

    private final FeedbackService feedback;
    private final QuotaService quotas;

    public EnglishController(FeedbackService feedback, QuotaService quotas) {
        this.feedback = feedback;
        this.quotas = quotas;
    }

    /**
     * Corrects a presentation, within the account's quota. A correction that fails is not
     * counted. Nothing is stored here: the app keeps the result.
     */
    @PostMapping("/feedback")
    FeedbackResponse feedback(
            @RequestAttribute(SessionFilter.ACCOUNT) UUID account,
            @Valid @RequestBody FeedbackRequest request) {
        QuotaService.Reservation reservation = quotas.reserve(account);
        try {
            return feedback.correct(request);
        } catch (RuntimeException e) {
            quotas.release(reservation);
            throw e;
        }
    }
}
