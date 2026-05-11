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

## Manage Team Structure Conventions

Source: review comments from Victoria P. (`vicki3z`), manage team, on [manage-frontend#2226](https://github.com/mr-yum/manage-frontend/pull/2226).

- Prefer `@mr-yum/frontend-ui` components over `@mr-yum/yum-ui` when an equivalent exists. When a diff introduces `@mr-yum/yum-ui` imports for primitives like `FormControl`, `Select`, etc., check whether `frontend-ui` already covers that primitive and ask the author to switch.
- Push feature-scoped state and handlers into the feature subcomponent that owns them. A parent page that composes a feature panel should receive parsed/derived data from the panel via callbacks, not own the parsing state and lifecycle itself.
  - Example: CSV parsing state (`parsedCsv`, `isCsvParsed`, `handleCsvFiles`, parse error handling) belongs in `*SetupPanel`, with the parent only receiving the resulting line items, customer info, and venue name.
  - When reviewing, flag large blocks of feature-specific `useState` / handlers in a top-level page component that could be encapsulated in the child panel.
- Co-locate closely related files in a single feature folder. A component, its sibling action buttons, and its parser/util module should live together (e.g., `CsvUpload.tsx`, `DownloadCsvTemplateButton.tsx`, and `parseInvoiceCsv.ts` in the same `InvoiceGenerator/` subfolder), not split between a generic `components/` root and the feature folder.

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
