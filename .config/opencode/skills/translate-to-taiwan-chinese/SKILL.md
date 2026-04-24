---
name: translate-to-taiwan-chinese
description: "Translates text (usually English) into Taiwan-appropriate Traditional Chinese, pitched for a 70-year-old parent who is not technically savvy. Use when the user asks to translate, rewrite, or localise text for a Taiwanese elder, mentions 'for my mum/dad', 'for my parent', 'Taiwan Chinese', '繁體中文', '正體中文', or asks to make a message readable for a non-technical older Taiwanese reader. Runs the translation through `opencode run` using the Kimi K2.5 model (Kimi K2.6 does not exist yet, bump the `-m` flag once it ships)."
---

# Translate to Taiwan Traditional Chinese (for a 70-year-old parent)

Delegate the translation to the Kimi K2.5 model via `opencode run`, with a prompt that encodes the audience, the register, and the Taiwan-specific vocabulary rules.

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
- Do not paraphrase or pre-edit the English source; let Kimi do the translation.

### 2. Invoke Kimi via opencode

Run the following from the shell. Pass the source text inside the HEREDOC exactly as given.

```bash
opencode run -m opencode/kimi-k2.5 "$(cat <<'EOF'
You are translating text for a 70-year-old parent in Taiwan who is not technically savvy.

Translate the text between <source></source> into Taiwan-appropriate Traditional Chinese (繁體中文 / 正體中文).

Audience and register:
- Warm, respectful, everyday tone. Imagine a caring adult child writing to their elderly parent.
- Plain, conversational language. Avoid literary or bureaucratic phrasing.
- Short, clear sentences. Break long English sentences into two or three Chinese ones when it helps.
- If the source uses technical jargon, an acronym, or an app/product name, keep the name in its original form and add a brief plain-language gloss in parentheses the first time it appears (e.g. 'Zoom（一個可以視訊通話的軟體）').

Vocabulary and orthography rules (Taiwan, NOT Mainland or Hong Kong):
- Use Taiwan Traditional Chinese characters throughout. Never output Simplified Chinese.
- Prefer Taiwan vocabulary: 網路 (not 網絡/网络), 影片 (not 視頻), 軟體 (not 軟件/软件), 硬體 (not 硬件), 資訊 (not 信息), 檔案 (not 文件 when meaning 'file'), 滑鼠 (not 鼠標), 印表機 (not 打印機), 計程車 (not 出租車), 手機 (not 手机), 簡訊 (not 短信), 馬鈴薯 (not 土豆 when meaning 'potato'), 鳳梨 (not 菠蘿), 腳踏車 / 自行車 (not 單車 in the HK sense).
- Use Taiwan punctuation conventions: full-width 。，、；：？！, 「」 for primary quotes and 『』 for nested quotes, — for em dash only when truly needed.
- Numbers: use Arabic numerals for quantities, dates, times, prices, and phone numbers. Spell out small counts (一、兩、三) only when the source clearly does.
- Dates: Taiwanese parents usually read Gregorian dates as '2026年4月24日'. Do not use ROC (民國) dates unless the source does.
- Currency: convert prices only if the source asks for it; otherwise keep the original currency symbol and add a rough NTD equivalent in parentheses if it helps comprehension.

What to AVOID:
- Mainland-specific slang or political vocabulary.
- English words left untranslated when a common Taiwanese term exists.
- Overly formal openings like '敬啟者'; use warmer openers like '媽，' or '爸，' if the source is clearly addressed to the parent.
- Romanisation (pinyin/zhuyin) unless the source explicitly asks for a pronunciation guide.

Output format:
- Output ONLY the translated Traditional Chinese text. No preamble, no English commentary, no notes.
- Preserve paragraph breaks from the source.
- If the source contains a list, keep it as a list in the translation.

<source>
{{PASTE_SOURCE_TEXT_HERE}}
</source>
EOF
)"
```

Replace `{{PASTE_SOURCE_TEXT_HERE}}` with the exact source text before executing. The heredoc is single-quoted (`<<'EOF'`) so `$`, backticks, and backslashes in the user's text are not interpreted by the shell.

If the user's text itself contains the literal string `EOF` on its own line, change the heredoc marker to something unique (e.g. `END_OF_SOURCE`) to avoid an early termination.

### 3. Return the result

- Print the Kimi output directly back to the user. Do not add English commentary, apologies, or meta notes.
- If Kimi returned an obvious error or empty output, re-run once. If it still fails, surface the shell error to the user rather than fabricating a translation.

### 4. Iteration

If the user asks for adjustments (e.g. 'too formal', 'use 爸 not 父親', 'shorter sentences'), re-run the same command with the extra guidance appended under the 'Audience and register' section. Do not edit the output by hand; keep Kimi as the source of truth so the style stays consistent.

## Guardrails

- Never output Simplified Chinese. If Kimi slips and returns Simplified, re-run with a stronger reminder in the prompt ('The previous output contained Simplified characters, e.g. 网络. Re-translate entirely in Traditional Chinese, Taiwan vocabulary.').
- Do not translate technical identifiers that should stay in English (URLs, email addresses, usernames, file paths, code snippets, product names). Leave them as-is and wrap a brief Chinese explanation around them if needed.
- Do not add content the source did not contain. If the source is ambiguous, ask the user rather than inventing a detail.
- When Kimi k2.6 becomes available in `opencode models`, update the `-m opencode/kimi-k2.5` flag in the workflow above.
