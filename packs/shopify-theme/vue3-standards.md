---
description: Vue 3 patterns required for this theme — declared props/emits, computed for derived state, Composition API preference.
alwaysApply: true
---

# Vue 3 standards

Layered on top of `corporate-baseline/es6-standards.md`. The ES6+ rules
(destructuring, optional chaining, nullish coalescing, etc.) live there;
this fragment covers the Vue-specific surface.

## Props

- **Must have `type`** — `String`, `Number`, `Boolean`, `Array`, `Object`, or a custom validator.
- **Must have `default`** — or be marked `required: true`. Implicit `undefined` defaults bite at render time.
- **Use object form**, not array form:
  ```js
  // good
  props: {
    title: { type: String, default: '' },
    count: { type: Number, required: true },
  }
  // worse — no type, no default, no required
  props: ['title', 'count']
  ```
- **Don't mutate props.** They're owned by the parent. Copy to local state if you need to modify.

## Emits

- **Must be declared** via `defineEmits([...])` (Composition API) or `emits: [...]` (Options API).
- Emit names use kebab-case in templates (`@user-selected`) and camelCase / kebab-case consistently in JS. Pick a convention and hold it.
- Don't emit DOM events (`click`, `input`) up — they're already bubbling. Emit semantic events: `selected`, `submitted`, `dismissed`.

## Derived state

- **Use `computed`** for any value derived from props / state / store.
- **Never bake derived values into `data()` / `ref()` directly** — they won't react when source changes:
  ```js
  // wrong — `fullName` is a snapshot
  data() { return { fullName: this.first + ' ' + this.last }; }

  // right — `fullName` updates when first/last change
  computed: { fullName() { return this.first + ' ' + this.last; } }
  ```

## API choice

- **Composition API preferred** for new components — `<script setup>` form.
- **Mixed APIs in the same component** are a maintenance debt. Don't add Options-API methods to a `<script setup>` component, or vice versa.
- **Don't migrate working Options-API components for the sake of it.** If it works and isn't being touched, leave it. Migrate when you're already in the file for another reason.

## Reactivity gotchas

- **Destructuring `reactive` loses reactivity.** Use `toRefs` when destructuring:
  ```js
  const state = reactive({ count: 0, name: '' });
  const { count, name } = toRefs(state);  // count and name stay reactive
  ```
- **Don't replace a `ref` value — assign `.value`:**
  ```js
  const items = ref([]);
  items.value = newArray;     // good
  items = newArray;           // wrong: replaces the ref itself
  ```
- **`v-model` on custom components**: define both `modelValue` prop AND emit `update:modelValue`.

## Cleanup

- **`onMounted` listeners need `onBeforeUnmount` removal.** Same rule as in
  `corporate-baseline/performance-baseline.md`; specifically applies to
  Vue lifecycle here.

## Verify

- ESLint with `eslint-plugin-vue` configured to `vue3-recommended` catches most of these.
- Grep for `data() { return { ... +`/`...this.` — flag derived values that should be `computed`.
- Grep for `props: [` — flag array-form props for migration to object form.
