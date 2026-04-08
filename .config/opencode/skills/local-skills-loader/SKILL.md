---
name: local-skills-loader
description: Loads and executes the user's personal skill collection from a folder they've granted Cowork access to. MANDATORY TRIGGERS: any time the user references a personal skill by name ("use the X skill", "run my X skill", "with the X skill, ...", "apply the X skill"), asks "what skills do I have" or "list my skills", or names a skill that isn't in your built-in skill list. The user keeps a frequently-edited skill collection on their host machine and this is the only way to reach it from inside Cowork — use it whenever they refer to a skill by a name you don't recognize.
---

# Local Skills Loader

The user maintains a personal skill collection on their host machine, edited frequently, that is not part of Cowork's built-in skill set. This skill bridges that gap: when the user references one of their personal skills, you locate it in the folder they granted Cowork access to, read it fresh, and follow it.

## Step 1 — Locate the skills root

The user has granted Cowork access to a folder containing their personal skills. You need to find it. Try these in order:

1. Check what folders the user has granted you access to in this session. The skills folder is the one that contains subdirectories, each with a `SKILL.md` file inside.
2. Common candidate paths to probe:
   - `~/.claude/skills/`
   - `~/.config/opencode/skills/` (this is where the user's actual files live; `~/.claude/skills` is a symlink to it)
   - Any directory under `/mnt/` containing folders with `SKILL.md` files
3. If you genuinely cannot find it, ask the user one short question: "Where did you grant access to your skills folder?" Don't guess.

Once you find it, remember the path for the rest of the conversation.

## Step 2 — Resolve the skill the user named

When the user says something like "use the X skill", "run my X skill", or just "/X":

1. Look for `<skills-root>/X/SKILL.md`. Exact match first.
2. If no exact match, list close matches by name (Levenshtein-ish or substring) and ask which one they meant. Don't pick silently.
3. If there's no match at all, list the available skills (see Step 4) and ask.

## Step 3 — Read and follow the skill

Once resolved:

1. Read the entire `SKILL.md`. Always read it fresh — do not rely on a version you may have seen earlier in the conversation, because the user edits these often.
2. Read any files the SKILL.md tells you to consult (typically under `references/`, sometimes `scripts/` or `assets/`). Follow the SKILL.md's own guidance about when to read what — don't slurp everything.
3. From this point, treat the loaded SKILL.md as authoritative for the task at hand. Follow its instructions exactly as if it were a first-class skill that had been triggered natively. Its rules override your defaults for the duration of the task.
4. If the SKILL.md references scripts (e.g. `python scripts/foo.py`), run them. The skills folder is mounted read-only from the host, so don't try to modify it — if the skill asks you to create files, put them in your working directory instead.

## Step 4 — Listing skills

When the user asks "what skills do I have", "list my skills", or similar:

1. List every subdirectory of the skills root that contains a `SKILL.md`. Skip dotfiles and any directory named `.system` or `_*`.
2. For each, read **only** the YAML frontmatter at the top of `SKILL.md` — `name` and `description`. Don't read the body. If the description is multi-line, show just the first sentence.
3. Present as a compact list: `- name — first sentence of description`.
4. Don't editorialize. The user knows what their skills do; they want a quick index.

## Notes on behavior

- **Always re-read.** The user edits these skills frequently. Even within a single session, if they reference the same skill twice, read `SKILL.md` again the second time in case it changed. The whole reason this loader exists is to keep the central directory as the source of truth.
- **No caching assumptions.** Don't assume any skill you used earlier in the conversation is still the same.
- **Read-only mount.** The host folder is mounted read-only. Never attempt to write into the skills directory. If the user asks you to *edit* a skill, tell them: "I can't edit the skills folder from inside Cowork — it's mounted read-only. Edit it on your host (the file is at `<full path>`) and I'll see the new version next time you reference it."
- **Don't pre-load everything.** Only read the skills the user actually invokes. Reading every skill at session start would burn context for no reason.
- **Trigger generously.** If the user mentions a name that sounds like it could be one of their skills and isn't already in your built-in list, default to running this loader rather than asking.
