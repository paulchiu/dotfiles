# Exemplar: CUSM-820 rewritten card (2026-07-06)

The reference instance of the extended template: a read-only Phase 2 swap card for the four menuItemUpsell read methods. Study the density, the footgun blocks with file:line evidence, the write-path N/A declarations (Out of scope, Verification), the sibling-ticket coordination (CUSM-828/830/832/834/836), the corrected-guess Q&A, and the preserved original in the `+++` collapsible. Two caveats: this card shipped with em dashes before the no-em-dash rule was codified (copy its structure, not that punctuation), and it predates the `Derived from typeorm@` stamp convention, so its typeorm-internals claims carry no version stamps. Its soft-delete guidance ('scoped on findOne and on joins', `deletedAt: null` inside includes) happens to match the current `typeorm@=0.3.30` pin; a new card must stamp such claims per the SKILL's Version discipline note, not copy them unstamped.

---

## Summary

Swap the four Phase 1 read-method store primitives from TypeORM to Prisma, following `docs/typeorm-to-prisma-migration-phase-2.md`: decouple each method's return type from `@mr-yum/legacy-entities` to a standalone `Mapped*` interface, rewrite the query as Prisma plus a strictest-first mapper, and keep every Phase 1 snapshot passing unchanged.

## Governing docs (read before coding)

- `docs/typeorm-to-prisma-migration-phase-2.md` — source of truth for this card (swap Store internals). Owns the delta over Phase 1.
- `docs/typeorm-to-prisma-migration-phase-1.md` — universal invariants (no `as`, no `Object.assign`, no `package-lock.json` diffs), store anatomy, snapshot rules. Every rule still applies.
- `.claude/commands/oscar-move-typeorm-query-to-store.md`, `.claude/commands/jenny-c-phase2-migrate-service-to-prisma.md` — companion workflows; the mapper-construction and consumer-update rules below come from them.

## Acceptance criteria

- [ ] All four read methods use Prisma internals; no `Repository<...>`, `createQueryBuilder`, `findOne`, or `getManyAndCount` remains in them (the store keeps `@InjectRepository` only for the out-of-scope mutation methods until the sibling cards land)
- [ ] Method names and parameter shapes are unchanged; return types become standalone `Mapped*` interfaces whose field shape (columns, scalar types, nullability) mirrors what TypeORM returned, so snapshots don't move
- [ ] The new mapper file imports zero `@mr-yum/legacy-entities`
- [ ] No `as` and no `Object.assign` anywhere in the diff (strictest-first mapper construction)
- [ ] Phase 1 store snapshots in `test/integration/menuItemUpsell/__snapshots__/` pass unchanged
- [ ] New service-level integration specs pass against the current TypeORM code (PR 1) and unchanged after the swap (PR 2)
- [ ] Validation chain green (see Verification)

## Scope

### In scope

Four read methods across two stores; decouple return type + swap internals for each:

| Store method                                                | Location                                      | Prisma target                                                                       |
| ----------------------------------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------------- |
| `MenuItemToItemUpsellGroupStore.findByMenuItemIdNonDynamic` | `store/menuItemToItemUpsellGroup.store.ts:35` | `prisma.menuItemUpsellGroups.findMany` with conditional nested `include`            |
| `MenuItemToItemUpsellGroupStore.findById`                   | `store/menuItemToItemUpsellGroup.store.ts:57` | `prisma.menuItemUpsellGroups.findFirst({ where: { id } })`                          |
| `MenuItemUpsellGroupStore.findPaginatedForVenueId`          | `store/menuItemUpsellGroup.store.ts:24`       | `prisma.$transaction([findMany, count])` with `has` operator                        |
| `MenuItemUpsellGroupStore.findByVenueAndId`                 | `store/menuItemUpsellGroup.store.ts:60`       | `prisma.menuItemUpsellGroup.findFirst({ where: { venueId, id, deletedAt: null } })` |

Also in scope: introduce the `Mapped*` interfaces and mapper for these three tables; narrow the read-method consumers (service delegators, resolver `@Parent()`/`@ResolveField`) to the mapped types.

### Out of scope

- Every mutation store method (`createMany`, `removeById`, `updateLink`, `saveUpsellGroup`, `updateUpsellGroup`, `deleteGroupIfEmpty`, `repositionUpsellItem`, etc.). Those swap on CUSM-828/830/832/834/836; leave their TypeORM internals and their `@InjectRepository` params in place.
- Write-path audits (FK carve-outs, transform inverses, tri-state, null coercion, default parity, column completeness). All four methods are reads; the doc's write-path machinery does not apply. State this in the PR.
- Deleting the legacy entity or fully removing `@mr-yum/legacy-entities` imports from the store. That END state (Phase 3) lands once the sibling mutation cards have also swapped; this card only removes legacy imports from the new mapper and the read paths.

## Implementation guidance

Work the Phase 2 doc checklist in order: (A) decouple return types, (B) build the mapper, (C) swap each query, (D) narrow consumers.

**Footgun 1: the plural/singular model names are transposed from intuition.**

```typescript
prisma.menuItemUpsellGroups; // → table menu_items_to_upsell_groups (the LINK, entity MenuItemToItemUpsellGroup)
prisma.menuItemUpsellGroup; // → table menu_item_upsell_groups   (the GROUP, entity MenuItemUpsellGroup)
```

`MenuItemToItemUpsellGroupStore.findByIdForVenueOrFail` (`store/menuItemToItemUpsellGroup.store.ts:73`) already uses `prisma.menuItemUpsellGroups` for the link; copy that.

**Footgun 2: soft-delete is not automatic in Prisma** (doc §Soft delete handling). TypeORM auto-scopes `deleted_at IS NULL` for any entity with a `@DeleteDateColumn`, on `findOne` and on joins. Prisma does not. The group (`menuItemUpsellGroup.entity.ts:142`) and the upsell item (`menuItemUpsell.entity.ts:66`) both have one; the link table (`menu_items_to_upsell_groups`) does not, so `findById` needs no filter. Verify before adding, per the doc: an unnecessary filter silently drops rows.

**Footgun 3: `{ isDynamic: { not: true } }` does not equal `IS NOT TRUE` here.** This repo's Prisma datasource is CockroachDB; its compiler emits `is_dynamic <> $1` for `not: true`, excluding `NULL` (`isDynamic` is `Boolean?`, `schema.prisma:1070`). The TypeORM originals use `IS NOT TRUE` (`menuItemToItemUpsellGroup.store.ts:51`, `menuItemUpsellGroup.store.ts:50`), matching `FALSE` and `NULL`. Use `OR: [{ isDynamic: false }, { isDynamic: null }]`.

### A. Decouple the return types (doc checklist step 2, do this first)

Declare standalone interfaces in a new `store/menuItemUpsell.mapper.ts` (or colocate per `cuisine.store.ts`), importing nothing from `@mr-yum/legacy-entities`. Fields mirror the columns TypeORM returned (names, scalar types, nullability):

```typescript
export interface MappedMenuItemUpsellGroup {
  id: string;
  name: string;
  minQuantity: number;
  maxQuantity: number | null;
  available: boolean;
  groupType: string;
  selectType: string;
  orderingType: string[];
  selectRequirement: string;
  hasPreselectedOption: boolean;
  respectCartQuantity: boolean;
  venueId: string;
  isDynamic: boolean | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  displayViewRequirement: string; // 👈 renamed from Prisma `displayViewSelectRequirement`
}

export interface MappedMenuItemUpsell {
  id: string;
  name: string;
  position: number;
  available: boolean;
  showFullPrice: boolean;
  menuItemId: string;
  groupId: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}

export interface MappedMenuItemToItemUpsellGroup {
  id: string;
  menuItemId: string;
  upsellGroupId: string;
  position: number;
  createdAt: Date;
  updatedAt: Date;
  // present only when findByMenuItemIdNonDynamic is called with fetchUpsellGroupsInQuery
  upsellGroup?: MappedMenuItemUpsellGroup & { upsells: MappedMenuItemUpsell[] };
}
```

This replaces `MenuItemToItemUpsellGroupRecord = Omit<MenuItemToItemUpsellGroup, ...>` (`store/menuItemToItemUpsellGroup.store.ts:22`). Land it as its own commit (types only) before the Prisma swap; every Phase 1 snapshot must still pass against the TypeORM code with the return types renamed. If a snapshot drifts, the interface is wrong, not the snapshot.

### B. Build the mapper (strictest-first; never `as`, never `Object.assign`)

Doc §Mapper construction preference. These are all scalar rows, so a **plain typed object literal** compiles for every field, including the `displayViewRequirement` rename; do not reach for `Object.assign`. Note: the existing `toUpsellGroupEntity`/`toUpsellItemEntity` in `menuItemUpsell.store.ts:24,33` use `Object.assign` (Phase 1 era) — do **not** copy them; they are the banned pattern.

```typescript
export const toMappedMenuItemUpsellGroup = (
  row: Prisma.MenuItemUpsellGroupGetPayload<Record<string, never>>,
): MappedMenuItemUpsellGroup => ({
  id: row.id,
  name: row.name,
  // ... every scalar column ...
  isDynamic: row.isDynamic, // boolean | null on both sides, no coercion
  displayViewRequirement: row.displayViewSelectRequirement,
});
```

`venueId` is non-null in Prisma, so no fail-loud guard is needed. If any field forces you toward `Object.assign`, stop: tighten/loosen the `Mapped*` field to match Prisma, add a conversion helper, or fail loud (doc §When neither compiles) — never `Object.assign`.

### C. Swap each query

1. **`findByMenuItemIdNonDynamic`** — returns `MappedMenuItemToItemUpsellGroup[]`:

   ```typescript
   const rows = await this.prisma.menuItemUpsellGroups.findMany({
     where: {
       menuItemId,
       upsellGroup: {
         OR: [{ isDynamic: false }, { isDynamic: null }], // footgun 3
         groupType,
         deletedAt: null, // 👈 footgun 2: the join is soft-delete scoped in TypeORM
       },
     },
     orderBy: { position: "asc" }, // 👈 the link entity has an entity-level default order (see below)
     include: fetchUpsellGroupsInQuery
       ? {
           upsellGroup: {
             include: { menuItemUpsells: { where: { deletedAt: null } } },
           },
         } // 👈 upsells are soft-deletable
       : undefined,
   });
   return rows.map(toMappedLink); // maps menuItemUpsells → upsells, displayViewSelectRequirement → displayViewRequirement
   ```

   **Ordering (snapshot-critical):** the link entity is `@Entity('menu_items_to_upsell_groups', { orderBy: { position: 'ASC' } })` (`menuItemToUpsellGroup.entity.ts:15`), so `getMany()` returns `position ASC` without an explicit `.orderBy()`. Prisma has no implicit order; omit `orderBy` and the snapshot churns.

2. **`findById`** — returns `MappedMenuItemToItemUpsellGroup | undefined`:

   ```typescript
   const row = await this.prisma.menuItemUpsellGroups.findFirst({
     where: { id },
   });
   return row ? toMappedLink(row) : undefined;
   ```

   Consumed within `MenuItemUpsellService` only (`menuItemUpsell.service.ts:67,145,168`, two inside mutation re-fetches); all three narrow to the mapped type together.

3. **`findPaginatedForVenueId`** — returns `[MappedMenuItemUpsellGroup[], number]`. `orderingType` is `String[]`, so `{ orderingType: { has } }` compiles to `ordering_type @> $param` — no `$queryRaw`, correcting the parent card's Pattern B guess:

   ```typescript
   const where: Prisma.MenuItemUpsellGroupWhereInput = {
     venueId,
     ...(searchQuery?.trim()
       ? { name: { contains: searchQuery, mode: "insensitive" } }
       : {}), // ilike %q%
     ...(orderingType ? { orderingType: { has: orderingType } } : {}),
     ...(includeDynamic
       ? {}
       : { OR: [{ isDynamic: false }, { isDynamic: null }] }), // footgun 3
   };
   const [rows, total] = await this.prisma.$transaction([
     this.prisma.menuItemUpsellGroup.findMany({
       where,
       orderBy: { createdAt: "desc" },
       skip,
       take: limit,
     }),
     this.prisma.menuItemUpsellGroup.count({ where }),
   ]);
   return [rows.map(toMappedMenuItemUpsellGroup), total];
   ```

4. **`findByVenueAndId`** — returns `MappedMenuItemUpsellGroup | undefined`:

   ```typescript
   const row = await this.prisma.menuItemUpsellGroup.findFirst({
     where: { venueId, id, deletedAt: null }, // 👈 footgun 2
   });
   return row ? toMappedMenuItemUpsellGroup(row) : undefined;
   ```

### D. Update consumers (doc §Updating consumers — narrow / widen / convert)

Return types shift from legacy entity to `Mapped*`, so consumers retype. Default is **narrow**:

- `MenuItemUpsellService.findByIdMenuItemToItemUpsellGroup` + the two internal call sites (`:145`, `:168`) → `MappedMenuItemToItemUpsellGroup`. Narrow.
- `MenuItemUpsellGroupService.findByIdUpsellGroupForVenueId` / `...OrFail` (`:87`, `:94`) and `findPaginatedUpsellGroupsForVenueId` (`:69`) → mapped types. `PaginatedResponse` is structurally typed, so the paginated query resolver just narrows.
- The root query/resolver methods keep their legacy `@ObjectType()` GraphQL decorators (`@Query(() => MenuItemUpsellGroup)`, `@Resolver(MenuItemUpsellGroup)`, `PaginatedResponse(MenuItemUpsellGroup)`); only the TS return/`@Parent()` types become `Mapped*`. NestJS walks `@Field()` by name, so the mapped shape serializes identically.
- **Convert-at-boundary candidate — flag and verify:** `menuItemToUpsellGroup.resolver.ts` (`@Resolver(MenuItemToItemUpsellGroup)`) binds `@Parent() menuItemToUpsell: MenuItemToItemUpsellGroup` and calls `ctx.dataLoader.MenuItemToItemUpsellGroup.upsellGroup.load(...)`. If the dataLoader key requires the legacy shape, narrowing the `@Parent()` won't typecheck — use a boundary conversion helper (doc option 3) and grep-verify no consumer reads a fabricated field. If structural narrowing compiles, prefer it. Run jenny's pre-flight checks (no `instanceof`, field-shape-only reads, no `class-transformer`, structural `PaginatedResponse`) before deciding.

### Constructor wiring

- `MenuItemToItemUpsellGroupStore` already injects `prisma` (`:32`). Reuse it; keep `upsellToItemRepository` for out-of-scope methods.
- `MenuItemUpsellGroupStore` does not inject Prisma yet. Add `private readonly prisma: PrismaClient` (import from `@mr-yum/mr-yum-db-schema`), keep the three repositories for out-of-scope methods.

### When uncertain

If a snapshot diffs, a filter clause, the ordering, or the mapper is wrong; fix the query, not the snapshot. If the dataLoader seam or the `isDynamic`/`has` semantics behave unexpectedly, stop and surface it rather than reaching for `Object.assign`, `as`, or `$queryRawUnsafe`.

## Testing

- **Add a service-level integration spec** (doc §Phase 2 testing) at `test/integration/menuItemUpsell/menuItemUpsellGroup.service.integration.spec.ts` (and one for `MenuItemUpsellService.findByIdMenuItemToItemUpsellGroup`) covering the read matrix: matching rows, exclusion, ordering, pagination skip/limit, whitespace/empty search, cross-venue isolation, soft-delete exclusion, and the `isDynamic` null case. None exists today (only Phase 1 store-level specs). Land it green against the current TypeORM code in PR 1.
- **Phase 1 store snapshots** must pass unchanged after the swap — the `null`/`undefined`, `Date`/`string`, LEFT-JOIN-nullable-relation regression classes are exactly what they catch (doc §Snapshot reuse).
- **No unit spec may mock the migrating layer:** no `Repository`/`QueryBuilder` mock in PR 1, no store mock in PR 2.

## Stacked PR shape

- **PR 1** — service-level integration specs against current TypeORM; every assertion green before merge.
- **PR 2** — stacked on PR 1: (commit 1) decouple return types to `Mapped*`; (commit 2) mapper + Prisma swap + consumer narrowing. Every PR 1 assertion and Phase 1 snapshot passes unchanged. Run a Codex review pass handing it both migration docs, then CodeRabbit per branch, before pushing.

## Verification

Doc validation chain, in order:

```bash
npm run fix:formatting && npm run fix:linting
npm run check:typing && npm run check:linting && npm run check:formatting
npm run test:unit -- menuItemUpsell
npm run test:integration -- menuItemUpsell   # Phase 1 snapshots + new service specs, zero snapshot writes
```

- [ ] `git grep -nE 'createQueryBuilder|getManyAndCount' src/modules/menuItemUpsell/store/menuItemUpsellGroup.store.ts` returns only out-of-scope methods (`deleteGroupIfEmpty` stays on TypeORM; that is CUSM-836)
- [ ] `git grep -n '@mr-yum/legacy-entities' src/modules/menuItemUpsell/store/menuItemUpsell.mapper.ts` is empty
- [ ] `git grep -nE 'Object\.assign|\bas\b' <the diff>` shows no casts or `Object.assign` in the swapped methods or mapper
- [ ] Write-path audits N/A (all reads) — noted in the PR

## Risk tier

Low. Internal read-query swap plus a type-only decoupling behind stable method signatures, covered by Phase 1 snapshots and new service specs; no schema, no write path, no GraphQL contract change. One human reviewer.

## Due diligence

Run the [change due diligence checklist](https://app.notion.com/p/meandu/Ctrl-alt-delight-Change-Due-Diligence-Checklist-3803c6719946810f8b7edcb94b875130) before shipping.

- [ ] How it's used: all four are pure reads called by thin service delegators (`findMenuItemToUpsellGroup`, `findPaginatedUpsellGroupsForVenueId`, `findByIdUpsellGroupForVenueId`, `findByIdMenuItemToItemUpsellGroup`) feeding the manage upsell/upgrade admin resolvers (e.g. `paginatedUpsellGroupsByVenue`). Verified via graph callers + `git grep`; no other consumers.
- [ ] Blast radius: manage admin upsell/upgrade screens only. No guest/serve, POS, or payments. Behaviour pinned by Phase 1 snapshots + new service specs.
- [ ] Query-semantics subtleties most likely to diverge on real data: footgun 2 (soft-delete on group + upsell reads), footgun 3 (`is_dynamic IS NOT TRUE` null-inclusion on CockroachDB), and the link entity's default `position ASC` order. All covered by fixtures. No feature flag needed for a read swap behind snapshot coverage.

## Files likely involved

- `src/modules/menuItemUpsell/store/menuItemToItemUpsellGroup.store.ts`
- `src/modules/menuItemUpsell/store/menuItemUpsellGroup.store.ts`
- `src/modules/menuItemUpsell/store/menuItemUpsell.mapper.ts` (new — `Mapped*` interfaces + mappers)
- `src/modules/menuItemUpsell/menuItemUpsellGroup.service.ts`, `menuItemUpsell.service.ts` (narrow consumers)
- `src/modules/menuItemUpsell/menuItemToUpsellGroup.resolver.ts`, `menuItemUpsellGroup.resolver.ts` (retype `@Parent()`; convert dataLoader seam if needed)
- `test/integration/menuItemUpsell/*.service.integration.spec.ts` (new)

## Q&A

**Q (original card):** Does `findPaginatedForVenueId`'s `ordering_type @> ARRAY[...]` need `$queryRaw` / `$queryRawUnsafe` (Pattern B)?
**A:** No. `orderingType` is a Prisma scalar list (`String[]`), so `{ orderingType: { has: value } }` compiles to the same `@>` containment operator. All four methods are Pattern A.

**Q:** Is `{ isDynamic: { not: true } }` a faithful translation of `is_dynamic IS NOT TRUE`?
**A:** No, not on this repo's CockroachDB Prisma provider; it excludes `NULL`. Use `OR: [{ isDynamic: false }, { isDynamic: null }]` (footgun 3).

**Q:** Do the store methods keep returning legacy entities?
**A:** No. Per `docs/typeorm-to-prisma-migration-phase-2.md` step 2, the read return types decouple to standalone `Mapped*` interfaces (zero legacy-entity imports in the mapper). Field shape is unchanged so snapshots hold; consumers narrow to the mapped types.

+++ # Original description (pre-2026-07-06)

## Problem

Swap internals of the four read-method store primitives introduced in Phase 1 from TypeORM to Prisma.

## Scope

| Store method                                                | Pattern          | Prisma equivalent                                                                                                                                                                               |
| ----------------------------------------------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MenuItemToItemUpsellGroupStore.findByMenuItemIdNonDynamic` | Pattern A        | `prisma.menuItemUpsellGroups.findMany({ where: { menuItemId, upsellGroup: { isDynamic: { not: true }, groupType } }, include: ... })` — conditional include on `upsellGroup` + nested `upsells` |
| `MenuItemUpsellGroupStore.findPaginatedForVenueId`          | Pattern B likely | Postgres `ordering_type @> ARRAY[...]` not cleanly typed — use `$queryRaw` / `$queryRawUnsafe`; alternative: typed query with `has` operator if Prisma supports it                              |
| `MenuItemUpsellGroupStore.findByVenueAndId`                 | Pattern A        | `prisma.menuItemUpsellGroup.findFirst({ where: { venueId, id, deletedAt: null } })`                                                                                                             |
| `MenuItemToItemUpsellGroupStore.findById`                   | Pattern A        | `prisma.menuItemUpsellGroups.findFirst({ where: { id } })`                                                                                                                                      |

## Tests

Phase 1 integration + snapshot tests must pass unchanged.

## Acceptance Criteria

- [ ] All four methods use Prisma internals (no `Repository<...>` / `createQueryBuilder` remaining)
- [ ] Phase 1 snapshots unchanged
- [ ] Typing/linting/formatting/unit/integration tests pass
- [ ] No `as` keyword used for type casting

+++
