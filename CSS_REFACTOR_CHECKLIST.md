# Willow Camp CSS Refactor Checklist

Each item is a small, discrete task. Check off each as you complete it.

---

## Semantic Class Audit

- [ ] List all custom semantic classes currently defined in your CSS (ensure all use the `wc-` prefix).
- [ ] List all raw Tailwind utility classes used in your ERB templates for core UI elements.

---

## Documentation

- [ ] Create or update `STYLE_GUIDE.md` with a table of all semantic classes and their intended use.
- [ ] Add usage examples for each semantic class in the style guide.

---

## CSS Refactor

- [ ] For each UI component (card, button, input, etc.), ensure a semantic class exists with the `wc-` prefix (e.g., `wc-card`, `wc-button`, `wc-input`).
- [ ] In your CSS, define each `wc-` semantic class using Tailwind’s `@apply` and CSS variables.
- [ ] Remove direct Tailwind utility classes for core appearance from your ERB templates and replace with `wc-` semantic classes.
- [ ] Retain Tailwind utility classes only for layout/spacing tweaks (e.g., `mt-2`, `flex`, `gap-2`).

---

## Theme Support

- [ ] Ensure all semantic classes use CSS variables for colors, backgrounds, and borders.
- [ ] Test theme switching (solarized/tokyo) and fix any issues with variable usage.
- [ ] Document how to add new themes or extend existing ones.

---

## User Stylesheet Support

- [ ] Implement logic to load a user-uploaded stylesheet after or instead of the default stylesheet.
- [ ] Test that user stylesheets can override all semantic classes.
- [ ] Document the process for users to upload and target semantic classes in their CSS.

---

## Accessibility

- [ ] Review all templates for semantic HTML structure.
- [ ] Add ARIA attributes where needed.
- [ ] Test keyboard navigation and screen reader compatibility.

---

## Testing

- [ ] Test the UI with the default stylesheet and both themes.
- [ ] Test the UI with a user-uploaded stylesheet (overriding and replacing).
- [ ] Validate that all UI elements remain usable and visually consistent.

---

## Maintenance

- [ ] Update the style guide whenever new semantic classes are added.
- [ ] Periodically audit templates for raw Tailwind utility class usage and refactor as needed.
