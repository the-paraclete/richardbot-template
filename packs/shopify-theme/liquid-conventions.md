---
description: Liquid template conventions — image_url filter, render over include, bounded loops.
alwaysApply: false
triggers:
  prompt:
    - "img_url"
    - "image_url"
    - "include"
    - "{% render"
    - "{% for"
    - ".liquid"
---

# Liquid conventions

## Filters

- **Use `| image_url`**, not `| img_url`. `img_url` is deprecated; `image_url` is the supported filter with width/format params.
- Specify width when you know it: `{{ product.featured_image | image_url: width: 400 }}` — Shopify generates responsive variants only when asked.

## Snippets

- **Use `{% render \'snippet-name\' %}`**, not `{% include \'snippet-name\' %}`. `include` is deprecated and exposes the parent scope to the snippet (a source of subtle bugs). `render` is scope-isolated.
- Pass data explicitly: `{% render \'snippet\', product: product, index: forloop.index %}`.

## Loops

- **Never `{% for %}` over a large collection without `limit:`.** `products.all`, `collections.all`, etc. can be hundreds or thousands of items. Use `limit:` + pagination.
- **No nested `{% for %}` loops** — O(n²) over Shopify collections is a perf nightmare. Assign intermediate values to variables; restructure.

## Performance

- Assign metafield reads to variables; don\'t re-fetch in a loop body. Each metafield access is a query.

## Verify

- Visual check: every `{% include %}` should be `{% render %}`; every `| img_url` should be `| image_url`.
- Lighthouse: collection / search pages should stay under their LCP budget after any Liquid changes.
