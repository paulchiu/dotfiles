---
name: reviewing-candidates
description: "Analyses resumes and interview transcripts, then crafts professional recruiter feedback. Use when reviewing a candidate's resume, writing interview feedback, or drafting hiring decisions."
---

# Reviewing Candidates

Analyse resumes and interview transcripts to produce structured reports and professional recruiter feedback.

## Resume Review Process

When a resume is provided:

1. **Analyse the resume** and produce a structured report:
   - One line summary of the candidate's experience
   - Front-end skills and experience (with years e.g. 2020 to 2022), citing work history
   - Back-end skills and experience (with years), citing work history
   - Notable projects or achievements
   - Potential fit for full-stack roles

2. **Ask for feedback** — after delivering the analysis, ask the user for their raw feedback about the candidate.

3. **Rewrite the feedback** into a polished, professional message. If the feedback is addressed to a specific recruiter, use the greeting format. If it's for a system/feedback form (e.g. HiBob), omit the greeting and write the feedback directly without addressing anyone.

   For recruiter:
   ```
   Hi [recruiter name],

   I think [we can | we will not] proceed with the candidate to the next stage.

   I liked that:
   - [Brief, concise, positive observation 1]
   - [Brief, concise, positive observation 2]
   - [Brief, concise, positive observation 3 if applicable]

   [Optional: I do have concerns about:
   - [Brief, concise, concern 1]
   - [Brief, concise, concern 2]
   - [Brief, concise, concern 3 if applicable]]

   [Optional: Additional context, questions, or next steps]
   ```

   For system/feedback form:
   ```
   I think [we can | we will not] proceed with the candidate to the next stage.

   I liked that:
   - [Brief, concise, positive observation 1]
   - [Brief, concise, positive observation 2]
   - [Brief, concise, positive observation 3 if applicable]

   [Optional: I do have concerns about:
   - [Brief, concise, concern 1]
   - [Brief, concise, concern 2]
   - [Brief, concise, concern 3 if applicable]]

   [Optional: Additional context, questions, or next steps]
   ```

## Interview Feedback Process

When an interview debrief transcript is provided:

1. **Analyse the transcript** and provide structured feedback. If the feedback is addressed to a specific recruiter, use the greeting format. If it's for a system/feedback form (e.g. HiBob), omit the greeting and write the feedback directly without addressing anyone. Do not ask the user — infer from context (e.g. "entering into HiBob" or "post in the channel" = system form; "send to the recruiter" = recruiter).

   For recruiter:
   ```
   Hi [name],

   We [would like to proceed | unfortunately decided to not proceed] with the candidate to the next stage.

   In terms of feedback for the candidate.

   What we liked:
   - [Brief, concise, positive observation 1]
   - [Brief, concise, positive observation 2]
   - [Brief, concise, positive observation 3 if applicable]

   Our concerns:
   - [Brief, concise, concern 1]
   - [Brief, concise, concern 2]
   - [Brief, concise, concern 3 if applicable]

   [Optional: Additional context, questions, or next steps]
   ```

   For system/feedback form:
   ```
   We [would like to proceed | unfortunately decided to not proceed] with the candidate to the next stage.

   In terms of feedback for the candidate.

   What we liked:
   - [Brief, concise, positive observation 1]
   - [Brief, concise, positive observation 2]
   - [Brief, concise, positive observation 3 if applicable]

   Our concerns:
   - [Brief, concise, concern 1]
   - [Brief, concise, concern 2]
   - [Brief, concise, concern 3 if applicable]

   [Optional: Additional context, questions, or next steps]
   ```

## General Guidelines

- Professional, concise tone in all communications
- Focus on specific skills and experiences rather than personal characteristics
- Balance honesty with constructiveness when rewriting feedback
- Ensure the message is clear about the hiring decision
- Present all feedback in markdown format
- Use bullet points for easy readability
- Australian spelling
- Do not bold within bullet points
- When the context mentions a feedback system (e.g. HiBob, Greenhouse, Lever) or posting into a channel, assume the output is for a system/form entry — omit greetings and do not ask who to address it to
