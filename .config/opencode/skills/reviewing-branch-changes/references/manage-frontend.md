# Manage Frontend Review Notes

Load this only when reviewing `manage-frontend` or diffs that use `@mr-yum/frontend-ui`.

## `frontend-ui` Button Semantics

- `@mr-yum/frontend-ui` `Button` defaults to `type="button"` when it renders its own button element.
- Evidence in the published package:
  - `node_modules/@mr-yum/frontend-ui/dist/chunk-54LDE3YS.mjs`
  - `node_modules/@mr-yum/frontend-ui/dist/index.js`
  - implementation pattern: `const buttonType = asChild ? type : type ?? "button"`
- Practical review rule:
  - Do not flag missing `type="button"` on plain `frontend-ui` `<Button>` usages in forms.
  - Continue to require explicit `type="submit"` when submit behavior is intended.

## Important Exception

- This default does **not** protect raw HTML `<button>` elements inside forms.
- It also does **not** automatically protect `frontend-ui` buttons rendered with `asChild`, because the component uses the provided child element and only forwards `type` when explicitly supplied.
- Review raw `<button>` and `asChild` button compositions with normal HTML semantics in mind.
