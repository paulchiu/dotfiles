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

## Button Exceptions

- This default does **not** protect raw HTML `<button>` elements inside forms.
- It also does **not** automatically protect `frontend-ui` buttons rendered with `asChild`, because the component uses the provided child element and only forwards `type` when explicitly supplied.
- UI wrappers such as `InputRightElement asChild` do not turn a raw child `<button>` into a `frontend-ui` `Button`; review the rendered child element's native semantics.
- Review raw `<button>` and `asChild` button compositions with normal HTML semantics in mind.

## Drawer / Dialog Lifecycle

- `frontend-ui` `DrawerContent` wraps Radix `DialogPortal` and `Dialog.Content`.
- In this stack, content is mounted through Radix `Presence` with `present: forceMount || context.open`.
- Evidence in the installed packages:
  - `node_modules/@mr-yum/frontend-ui/dist/components/drawer/index.js`
  - `node_modules/@radix-ui/react-dialog/dist/index.js`
- Practical review rule:
  - Do not assume local state inside drawer/dialog/sheet content persists across close and reopen.
  - Before flagging "state should reset on reopen" issues, verify whether the relevant content is force-mounted or naturally unmounted on close.
  - Parent state outside the dialog content can still persist and may need explicit reset logic.
