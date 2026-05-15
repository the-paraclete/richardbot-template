---
description: Vue 2 patterns that don\'t work in Vue 3 — flag and replace.
alwaysApply: false
triggers:
  prompt:
    - "this.$on"
    - "$off"
    - "$once"
    - "Vue.set"
    - "Vue.delete"
    - "$listeners"
    - "v-for"
    - "v-if"
    - "filter"
---

# Vue 3 deprecations

These Vue 2 patterns are removed or replaced in Vue 3:

| Vue 2 | Vue 3 |
|---|---|
| `this.$on / $off / $once` (event bus pattern) | Use `mitt` or a Pinia store for cross-component eventing |
| `Vue.set(obj, key, value)` | Just assign: `obj[key] = value` — Vue 3 reactivity is proxy-based, handles new keys |
| `Vue.delete(obj, key)` | `delete obj[key]` |
| Filters: `{{ value \| filter }}` | Use computed properties or method calls: `{{ formatted }}` / `{{ format(value) }}` |
| `$listeners` | `$attrs` now contains both attrs and listeners |

## Template gotchas (still relevant)

- **`v-for` must have a unique `:key`.** Missing or duplicate keys break reactivity and animations.
- **Never use `v-if` and `v-for` on the same element.** In Vue 3, `v-if` has higher precedence — your `v-for` may not render what you expect. Wrap one in a `<template>` or use computed-filtered list.

## Verify

Grep the changed files for the deprecated patterns. Migrate to the Vue 3 equivalent before merge.
