---
name: translate-to-taiwan-chinese
description: "Translates text (usually English) into Taiwan-appropriate Traditional Chinese, pitched for a 70-year-old parent who is not technically savvy. Use when the user asks to translate, rewrite, or localise text for a Taiwanese elder, mentions 'for my mum/dad', 'for my parent', 'Taiwan Chinese', '繁體中文', '正體中文', or asks to make a message readable for a non-technical older Taiwanese reader. Performs the translation inline using whichever model is running this skill."
---

# Translate to Taiwan Traditional Chinese (for a 70-year-old parent)

Translate the source text inline using the rules below. Do not spawn a subprocess or delegate to another model; just produce the translation directly.

## Target Reader Profile

- 70-year-old parent living in Taiwan.
- Not technically savvy: unfamiliar with software, apps, cloud services, crypto, AI jargon, acronyms.
- Comfortable reader of everyday Traditional Chinese (繁體中文 / 正體中文).
- Prefers warm, respectful, plain language over formal or literary phrasing.

## Workflow

### 1. Gather the source text

- If the user pasted text in the message, use that verbatim.
- If the user gave a file path, read the file first and use its contents.
- If the text is ambiguous (e.g. an email with quoted replies), ask which portion to translate.
- Do not paraphrase or pre-edit the English source before translating.

### 2. Translate using the rules below

**Audience and register:**
- Warm, respectful, everyday tone. Imagine a caring adult child writing to their elderly parent.
- Plain, conversational language. Avoid literary or bureaucratic phrasing.
- Short, clear sentences. Break long English sentences into two or three Chinese ones when it helps.
- If the source uses technical jargon, an acronym, or an app/product name, keep the name in its original form and add a brief plain-language gloss in parentheses the first time it appears (e.g. `Zoom（一個可以視訊通話的軟體）`).

**Vocabulary and orthography (Taiwan, NOT Mainland or Hong Kong):**
- Use Taiwan Traditional Chinese characters throughout. Never output Simplified Chinese.
- Prefer Taiwan vocabulary: 網路 (not 網絡/网络), 影片 (not 視頻), 軟體 (not 軟件/软件), 硬體 (not 硬件), 資訊 (not 信息), 檔案 (not 文件 when meaning 'file'), 滑鼠 (not 鼠標), 印表機 (not 打印機), 計程車 (not 出租車), 手機 (not 手机), 簡訊 (not 短信), 馬鈴薯 (not 土豆 when meaning 'potato'), 鳳梨 (not 菠蘿), 腳踏車 / 自行車 (not 單車 in the HK sense).
- Use Taiwan punctuation: full-width 。，、；：？！, 「」 for primary quotes and 『』 for nested quotes. Avoid em dashes; use commas, parentheses, colons, or separate sentences.
- Numbers: use Arabic numerals for quantities, dates, times, prices, and phone numbers. Spell out small counts (一、兩、三) only when the source clearly does.
- Dates: Taiwanese parents usually read Gregorian dates as `2026年4月24日`. Do not use ROC (民國) dates unless the source does.
- Currency: convert prices only if the source asks for it; otherwise keep the original currency symbol and add a rough NTD equivalent in parentheses if it helps comprehension.

**What to AVOID:**
- Mainland-specific slang or political vocabulary.
- English words left untranslated when a common Taiwanese term exists.
- Overly formal openings like `敬啟者`; use warmer openers like `媽，` or `爸，` if the source is clearly addressed to the parent.
- Romanisation (pinyin/zhuyin) unless the source explicitly asks for a pronunciation guide.

**Output format:**
- Output ONLY the translated Traditional Chinese text. No preamble, no English commentary, no notes.
- Preserve paragraph breaks from the source.
- If the source contains a list, keep it as a list in the translation.

### 3. Iteration

If the user asks for adjustments (e.g. 'too formal', 'use 爸 not 父親', 'shorter sentences'), re-translate from the original source with the extra guidance applied. Don't patch the previous output by hand; regenerate so the style stays consistent.

## Guardrails

- Never output Simplified Chinese. If you catch yourself using Simplified characters (e.g. 网络, 软件), re-translate the affected sentences in Traditional.
- Do not translate technical identifiers that should stay in English (URLs, email addresses, usernames, file paths, code snippets, product names). Leave them as-is and wrap a brief Chinese explanation around them if needed.
- Do not add content the source did not contain. If the source is ambiguous, ask the user rather than inventing a detail.
- Do not guess Chinese characters for romanised personal names (e.g. `Chiu Hou Jong`). Keep romanised names in their original form unless the user provides the characters.
