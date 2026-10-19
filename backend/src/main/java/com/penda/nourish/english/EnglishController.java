package com.penda.nourish.english;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/english")
public class EnglishController {

    private final FeedbackService feedback;

    public EnglishController(FeedbackService feedback) {
        this.feedback = feedback;
    }

    /** Corrects a written presentation. Nothing is stored here: the app keeps the result. */
    @PostMapping("/feedback")
    FeedbackResponse feedback(@Valid @RequestBody FeedbackRequest request) {
        return feedback.correct(request);
    }
}
