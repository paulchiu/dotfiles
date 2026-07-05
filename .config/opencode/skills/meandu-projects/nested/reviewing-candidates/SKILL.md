---
name: reviewing-candidates
description: "Analyses resumes and interview transcripts, then crafts professional recruiter feedback. Use when reviewing a candidate's resume, writing interview feedback, or drafting hiring decisions."
---

# Reviewing Candidates

Analyse resumes and interview transcripts to produce structured reports and professional recruiter feedback.

## Output Destination

Infer the destination from context, do not ask:

- Recruiter message (e.g. "send to the recruiter"): open with `Hi [recruiter name],` then the feedback.
- System/feedback form (e.g. HiBob, Greenhouse, Lever, or "enter into HiBob", "post in the channel"): no greeting, write the feedback directly without addressing anyone.

## Resume Review

When a resume is provided:

1. Analyse it and produce a structured report:
   - One line summary of the candidate's experience
   - Front-end skills and experience (with years, e.g. 2020 to 2022), citing work history
   - Back-end skills and experience (with years), citing work history
   - Notable projects or achievements
   - Potential fit for full-stack roles
2. After delivering the analysis, ask the user for their raw feedback about the candidate.
3. Rewrite that feedback using this template (add the greeting only for a recruiter message):

   ```
   I think [we can | we will not] proceed with the candidate to the next stage.

   I liked that:
   - [Brief, concise, positive observations, 2-3 bullets]

   [Optional: I do have concerns about:
   - [Brief, concise concerns, 2-3 bullets]]

   [Optional: Additional context, questions, or next steps]
   ```

## Interview Feedback

When an interview debrief transcript is provided, analyse it and write feedback using this template (greeting rule as above):

```
We [would like to proceed | unfortunately decided to not proceed] with the candidate to the next stage.

In terms of feedback for the candidate.

What we liked:
- [Brief, concise, positive observations, 2-3 bullets]

Our concerns:
- [Brief, concise concerns, 2-3 bullets]

[Optional: Additional context, questions, or next steps]
```

## Guidelines

- Professional, concise tone; Australian spelling; markdown with bullet points
- Focus on specific skills and experiences, not personal characteristics
- Balance honesty with constructiveness; make the hiring decision clear
- Do not bold within bullet points
