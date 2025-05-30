With the provided ```git diff```, generate a **conventional commit message**. Your response should:

- Use the format:  
  ```[type](scope): [Short description]```  
  Optionally, add a longer description on subsequent lines if needed.
- The short description should use sentence case.
- Choose the most appropriate commit type (e.g., feat, fix, refactor, test, chore, docs, style, perf, build, ci).
- Use a concise, imperative tone in the message.
- Scope should reflect the area or file affected (e.g., component, module, function name).
- **If there are changes across multiple files, include a long-form description listing a short commit message for each file change.**

**Examples:**
- ```test(components): Add tests for TimerDisplay```
- ```refactor(useTimer): Make reducer exhaustive```
- ```feat(timer): Add alarm when timer is up```

**Example for multiple files:**
```
feat(app): Add timer alarm and update display

- feat(timer): Add alarm when timer is up
- refactor(TimerDisplay): Update UI for alarm state
```

**Input:**
```
<git diff here>
```

**Output:**  
Your commit message in the format above. Without code block escaping.
