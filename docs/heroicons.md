# Heroicons Usage Guide

This project uses the [heroicons](https://rubygems.org/gems/heroicons) gem for SVG icons.

## Basic Usage

Use the `heroicon` helper in your views:

```erb
<%= heroicon "magnifying-glass" %>
```

## Icon Variants

Heroicons provides 4 variants:
- `:outline` - Outlined style icons (default in this project)
- `:solid` - Filled style icons
- `:mini` - Smaller 20x20 icons
- `:micro` - Tiny 16x16 icons

```erb
<%= heroicon "magnifying-glass", variant: :outline %>
```

## Styling Icons

Pass HTML options including CSS classes:

```erb
<%= heroicon "magnifying-glass", options: { class: "h-4 w-4 text-primary-500" } %>
```

## Common Examples

```erb
<!-- Copy icon -->
<%= heroicon "document-duplicate", options: { class: "h-4 w-4" } %>

<!-- Close/X icon -->
<%= heroicon "x-mark", options: { class: "h-4 w-4" } %>

<!-- Success checkmark -->
<%= heroicon "check-circle", options: { class: "h-6 w-6 stroke-current" } %>

<!-- Error/warning icon -->
<%= heroicon "x-circle", options: { class: "h-6 w-6 stroke-current" } %>

<!-- Menu/hamburger icon -->
<%= heroicon "bars-3", options: { class: "h-6 w-6" } %>

<!-- Search icon -->
<%= heroicon "magnifying-glass", options: { class: "h-5 w-5" } %>
```

## Finding Icons

Browse all available icons at [heroicons.com](https://heroicons.com).

## Configuration

The default variant can be configured in `config/initializers/heroicons.rb`.