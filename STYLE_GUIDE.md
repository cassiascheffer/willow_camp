# Willow Camp CSS Style Guide

## Overview

This style guide defines the approach for writing, organizing, and overriding CSS in Willow Camp. It is designed to maximize maintainability, semantic clarity, and user extensibility, while leveraging TailwindCSS for rapid development and theming.

---

## 1. Semantic Class System

- All core UI elements must use semantic, intuitive class names prefixed with `wc-` (e.g., `.wc-card`, `.wc-button`, `.wc-post-title`).
- These classes form the “public API” for styling and theming, both for internal use and for user-uploaded stylesheets.
- Avoid using raw Tailwind utility classes for core appearance (colors, borders, typography) in your HTML. Use them only for layout or spacing tweaks.

---

## 2. Tailwind-Powered Semantic Classes

- Define all semantic classes in your main stylesheet (e.g., `application.css`) using Tailwind’s `@apply` directive and the `wc-` prefix.
- Example:
    ```css
    .wc-card {
      @apply bg-[var(--light-card)] dark:bg-[var(--dark-card)] border border-[var(--light-border)] dark:border-[var(--dark-border)] rounded-md p-5 transition-all duration-200;
    }
    ```
- Use CSS variables for all color and theme-related properties.

---

## 3. Naming Conventions

- Use `.wc-*` for all general UI and post-related components (e.g., `.wc-card`, `.wc-button`, `.wc-input`, `.wc-post-title`, `.wc-post-content`, `.wc-post-metadata`).
- Use `.wc-section-divider`, `.wc-alert`, `.wc-notice`, etc., for other semantic groupings.
- Avoid BEM notation; keep class names short, clear, and purpose-driven.

---

## 4. Theme Support

- All color, background, and border properties must use CSS variables.
- Theme switching is handled by toggling the `data-theme` attribute on the root element.
- Ensure all semantic classes respond correctly to theme changes.

---

## 5. User Stylesheet Support

- Users may upload a CSS file to override or replace the default stylesheet.
- When a user stylesheet is present, it should be loaded after the default stylesheet or replace it entirely.
- Document all semantic classes so users know what to target.

---

## 6. Accessibility

- Use semantic HTML elements and ARIA attributes as needed.
- Ensure that styling does not interfere with accessibility or usability.

---

## 7. Documentation

- Maintain this style guide and keep it up to date as new semantic classes are added.
- Provide examples for each class and describe its intended use.

---

## 8. Example Semantic Classes

| Class Name             | Purpose/Usage                        | Example HTML Usage                                 |
|------------------------|--------------------------------------|----------------------------------------------------|
| `.wc-card`             | Card containers, panels, widgets     | `<div class="wc-card">...</div>`                   |
| `.wc-button`           | Primary action buttons               | `<button class="wc-button">Save</button>`          |
| `.wc-input`            | Text inputs, textareas, selects      | `<input class="wc-input" />`                       |
| `.wc-alert`            | Error or alert messages              | `<div class="wc-alert">Error!</div>`               |
| `.wc-notice`           | Success or info messages             | `<div class="wc-notice">Saved!</div>`              |
| `.wc-post-title`       | Post/page titles                     | `<h1 class="wc-post-title">Title</h1>`             |
| `.wc-post-content`     | Main content of a post/page          | `<div class="wc-post-content">...</div>`           |
| `.wc-post-metadata`    | Author, date, tags, etc.             | `<div class="wc-post-metadata">By Jane</div>`      |
| `.wc-section-divider`  | Section breaks/dividers              | `<div class="wc-section-divider"></div>`           |
| `.wc-btn-secondary`    | Secondary action buttons/links       | `<a class="wc-btn-secondary">Cancel</a>`           |
| `.wc-notice`           | Inline notice messages               | `<p class="wc-notice">Notice text</p>`             |
| `.wc-alert`            | Inline alert messages                | `<p class="wc-alert">Alert text</p>`               |

---

## 9. Example: Defining a Semantic Class with Tailwind

```css
/* In application.css */
.wc-card {
  @apply bg-[var(--light-card)] dark:bg-[var(--dark-card)] border border-[var(--light-border)] dark:border-[var(--dark-border)] rounded-md p-5 transition-all duration-200;
}
```

---

## 10. Example: Using Semantic Classes in ERB

```erb
<!-- Good: semantic class for a card -->
<div class="wc-card">
  <h2 class="post-title">Welcome</h2>
  <p class="post-content">This is a post.</p>
</div>

<!-- Good: semantic class for a button -->
<button class="wc-button">Save</button>
```

---

## 11. Theme Switching

- Use the `data-theme` attribute on the root element to switch between themes.
- All semantic classes must use CSS variables for theme-dependent properties.
- Example:
    ```html
    <html data-theme="solarized">
    ```

---

## 12. User Stylesheet Guidance

- Users can override any semantic class by targeting it in their uploaded CSS.
- Example:
    ```css
    /* user-uploaded.css */
    .wc-card {
      background: #222;
      color: #fff;
      border-radius: 2rem;
    }
    ```
- For full replacement, user stylesheet can redefine all classes as desired.

---

## 13. Maintenance

- Update this guide whenever new semantic classes are added.
- Periodically audit templates for raw Tailwind utility class usage and refactor as needed.

---

## 14. Further Reading

- [TailwindCSS Documentation](https://tailwindcss.com/docs/)
- [MDN: CSS Custom Properties (Variables)](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)
- [Accessible Rich Internet Applications (ARIA)](https://www.w3.org/WAI/standards-guidelines/aria/)

---

**Keep your HTML semantic, your classes intuitive, and your CSS maintainable!**
