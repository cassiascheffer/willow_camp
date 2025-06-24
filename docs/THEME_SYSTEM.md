# Dual Theme System Documentation

This document explains how the dual theme system works in Willow Camp, allowing users to set separate themes for light and dark modes that automatically switch based on browser preferences.

## Overview

The dual theme system allows users to:
- Choose a specific theme for light mode (e.g., "cupcake", "emerald", "pastel")
- Choose a specific theme for dark mode (e.g., "dracula", "synthwave", "cyberpunk")
- Browse themes in horizontal scrolling galleries with visual previews
- Preview themes immediately when hovering over them
- Automatically switch between their chosen light/dark themes based on browser preference (`prefers-color-scheme`)

## Database Schema

Two fields in the `users` table handle theme preferences:
- `light_theme` (string, default: "light")
- `dark_theme` (string, default: "dark")

## User Model Methods

```ruby
def effective_light_theme
  light_theme.presence || "light"
end

def effective_dark_theme
  dark_theme.presence || "dark"
end
```

## All Available DaisyUI Themes

Both light and dark theme dropdowns include all available DaisyUI themes for maximum flexibility:

**Complete Theme List (35 themes):**
- light, dark, cupcake, bumblebee, emerald, corporate, synthwave, retro
- cyberpunk, valentine, halloween, garden, forest, aqua, lofi, pastel
- fantasy, wireframe, black, luxury, dracula, cmyk, autumn, business
- acid, lemonade, night, coffee, winter, dim, nord, sunset, caramellatte
- abyss, silk

**Theme Ordering:**
- **Light Mode Dropdown**: Sorted light to dark (light → wireframe → cupcake → ... → black → abyss → dark)
- **Dark Mode Dropdown**: Sorted dark to light (dark → abyss → black → ... → cupcake → wireframe → light)

Users can choose any theme for either light or dark mode preference, with intelligent brightness-based ordering for better user experience.

## JavaScript Controllers

The theme system is now split into two separate controllers for better separation of concerns:

### ThemeController (`theme_controller.js`) - Core Theme Management

Handles automatic theme switching and application without any UI components.

**Usage:**
```html
<html data-controller="theme"
      data-theme-light-theme-value="cupcake"
      data-theme-dark-theme-value="dracula">
```

**Features:**
- Detects browser color scheme preference on page load
- Applies appropriate theme (light or dark) based on preference
- Listens for browser color scheme changes and switches themes automatically
- Manages CSS transition timing
- Provides external API for theme updates

**Methods:**
- `connect()`: Initialize theme application and media query listener
- `disconnect()`: Clean up media query listener
- `applyCurrentTheme(speed)`: Apply correct theme based on browser preference
- `applyTheme(theme, speed)`: Apply specific theme with transition control
- `getCurrentTheme()`: Determine which theme to use based on preference
- `setTransitionSpeed(speed)`: Control CSS transition timing (fast/normal)
- `setupMediaQueryListener()`: Listen for browser color scheme changes
- `updateThemeValues(lightTheme, darkTheme)`: External API for updating theme preferences

### ThemeSelectorController (`theme_selector_controller.js`) - UI Selection

Manages horizontal galleries, theme previews, and visual selection states.

**Usage:**
```html
<div id="theme-controller" data-controller="theme" data-theme-light-theme-value="..." data-theme-dark-theme-value="...">
  <div data-controller="theme-selector" data-theme-selector-theme-outlet="#theme-controller">
    <!-- Horizontal theme galleries -->
  </div>
</div>
```

**Features:**
- Provides live preview when users hover over theme cards
- Manages visual selection states across horizontal galleries
- Updates form fields when selections change
- Auto-scrolls selected themes into view on page load
- Communicates with ThemeController via Stimulus outlets

**Methods:**
- `connect()`: Initialize theme galleries
- `previewTheme(event)`: Apply theme on hover via ThemeController
- `restoreTheme(event)`: Restore current theme when hover ends
- `selectTheme(event)`: Handle theme selection with visual state updates
- `updateFormField(themeType, themeValue)`: Update hidden form inputs
- `updateThemeIndicator(button, themeValue)`: Update UI indicators
- `updateGallerySelection(selectedButton)`: Manage visual selection states
- `scrollThemeIntoView(themeButton)`: Scroll selected theme card into view
- Checkmark management methods
- Gallery initialization methods

**Controller Communication:**
The ThemeSelectorController uses Stimulus outlets to communicate with ThemeController:
- `this.themeOutlet.applyTheme(theme, 'fast')` for previews
- `this.themeOutlet.applyCurrentTheme('fast')` for restoration
- `this.themeOutlet.updateThemeValues(light, dark)` for selections



## HTML Implementation

### Dashboard Layout

The dashboard layout uses the core theme controller without hardcoded themes:

```html
<html data-controller="favicon theme"
      data-theme-light-theme-value="<%= @author&.effective_light_theme %>"
      data-theme-dark-theme-value="<%= @author&.effective_dark_theme %>">
```

Note: No `data-theme="light"` attribute is set, allowing daisyUI to automatically apply the correct theme based on browser preference.

### Blog Layout

The blog layout uses the core theme controller without hardcoded themes:

```html
<html data-controller="favicon theme"
      data-theme-light-theme-value="<%= @author&.effective_light_theme || 'light' %>"
      data-theme-dark-theme-value="<%= @author&.effective_dark_theme || 'dark' %>">
```

Note: No `data-theme="light"` attribute is set, allowing daisyUI to automatically apply the correct theme based on browser preference.

### Settings Form

The settings form uses both controllers with outlet communication:

```html
<div id="theme-controller" data-controller="theme"
     data-theme-light-theme-value="<%= user.effective_light_theme %>"
     data-theme-dark-theme-value="<%= user.effective_dark_theme %>">
  
  <div data-controller="theme-selector" data-theme-selector-theme-outlet="#theme-controller">
    <!-- Light theme gallery -->
    <%= form.hidden_field :light_theme, value: user.effective_light_theme %>
    
    <!-- Selected theme indicator -->
    <div class="mb-3 p-3 bg-base-200 rounded-lg">
      <div class="flex items-center gap-3">
        <div data-theme="<%= user.effective_light_theme %>" class="bg-base-100 grid shrink-0 grid-cols-2 gap-1 rounded-md p-2 shadow-sm">
          <div class="bg-base-content size-2 rounded-full"></div>
          <div class="bg-primary size-2 rounded-full"></div>
          <div class="bg-secondary size-2 rounded-full"></div>
          <div class="bg-accent size-2 rounded-full"></div>
        </div>
        <span class="text-sm font-medium">Selected: <span class="capitalize font-bold"><%= user.effective_light_theme %></span></span>
      </div>
    </div>
    
    <!-- Horizontal scrolling theme gallery -->
    <div class="relative">
      <div class="flex gap-3 overflow-x-auto pb-3 scroll-smooth theme-gallery">
        <!-- Theme cards with previews -->
      </div>
      <!-- Fade indicators for scrolling -->
      <div class="absolute left-0 top-0 bottom-0 w-8 bg-gradient-to-r from-base-100 to-transparent"></div>
      <div class="absolute right-0 top-0 bottom-0 w-8 bg-gradient-to-l from-base-100 to-transparent"></div>
    </div>

    <!-- Similar structure for dark theme gallery -->
  </div>
</div>
```

### Theme Preview Cards

Each theme option is displayed as a card with a visual preview using DaisyUI's color variables:

```html
<button type="button" class="flex-shrink-0 theme-card p-3 bg-base-100 hover:bg-base-200 rounded-lg border-2 transition-all duration-200"
        data-theme-value="themename"
        data-theme-type="light"
        data-action="click->theme-selector#selectTheme mouseenter->theme-selector#previewTheme mouseleave->theme-selector#restoreTheme">
  <div class="flex flex-col items-center gap-2">
    <div data-theme="themename" class="bg-base-100 grid grid-cols-2 gap-1 rounded-lg p-2 shadow-sm">
      <div class="bg-base-content size-3 rounded-full"></div>
      <div class="bg-primary size-3 rounded-full"></div>
      <div class="bg-secondary size-3 rounded-full"></div>
      <div class="bg-accent size-3 rounded-full"></div>
    </div>
    <span class="text-xs font-medium capitalize text-center">themename</span>
    <!-- Checkmark for selected theme -->
  </div>
</button>
```

This creates theme cards with larger color preview grids, theme names, and selection indicators in a horizontally scrollable layout.

## User Experience Flow

1. **Page Load**:
   - daisyUI automatically applies the correct default theme based on browser preference (`light` for light mode, `dark` for dark mode)
   - ThemeController checks if user has custom theme preferences
   - Only applies custom themes if user selected non-default options (e.g., 'cupcake' instead of 'light')
   - ThemeSelectorController (on settings page) initializes visual states
   - Selected themes automatically scroll into view in their galleries
   - Theme preview cards show the actual colors of each theme
   - **No flash**: Proper theme is applied immediately without light-to-dark transition

2. **Theme Browsing** (Settings Page Only):
   - Users see horizontal galleries of all available DaisyUI themes with visual previews
   - Each theme card shows 4 colored dots representing base-content, primary, secondary, and accent colors
   - All themes are available in both galleries for maximum flexibility
   - **Brightness-Sorted Ordering**: Light gallery shows themes from lightest to darkest, dark gallery shows themes from darkest to lightest
   - **Horizontal Scrolling**: Users can scroll horizontally through all themes with smooth scrolling
   - **Visual Scroll Indicators**: Gradient fade effects and scroll hints indicate scrollable content
   - **Auto-Scroll to Selection**: Selected themes automatically scroll into view on page load

3. **Theme Interaction** (Settings Page Only):
   - **Smooth Hover Preview**: ThemeSelectorController calls ThemeController to apply themes with CSS transitions
   - **Fast Transitions**: Hover previews use faster transitions (0.15s) for responsive feel
   - **Hover Restore**: Moving mouse away from card restores the user's preferred theme smoothly
   - Clicking a theme card permanently selects it with normal transitions (0.3s)
   - Selected theme shows visual selection state (border, ring, checkmark) and updates the indicator above
   - **Mobile-Friendly**: Touch scrolling works naturally on mobile devices

4. **Form Submission**:
   - New theme preferences are saved to database via hidden form fields
   - Page reloads with correct theme applied based on browser preference
   - Hover previews and selection states work immediately after page load

5. **Browser Preference Changes** (All Pages):
   - ThemeController automatically switches themes when system dark/light mode changes
   - No page reload required
   - Works on blog pages, dashboard pages, and settings page
   - Theme preview cards (settings only) remain accurate to the applied theme

## Controller Updates

### UsersController
Permitted parameters include the dual theme fields:

```ruby
def user_params
  params.require(:user).permit(
    :name, :email, :password, :password_confirmation,
    :subdomain, :custom_domain, :blog_title,
    :light_theme, :dark_theme, :site_meta_description, :favicon_emoji
  )
end
```



## Migrations

Initial migration to add dual theme support:
```ruby
class AddThemePreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :light_theme, :string, default: "light"
    add_column :users, :dark_theme, :string, default: "dark"
  end
end
```

Migration to remove old single theme system:
```ruby
class RemoveThemeFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :theme, :string
  end
end
```

## DaisyUI Integration

The system uses DaisyUI's built-in theme switching via the `data-theme` attribute on the `<html>` element. All theme names correspond to official DaisyUI themes.

### Flash Prevention Configuration

To prevent the light-to-dark flash on page load, the system is configured with proper default theme handling:

```css
@plugin "daisyui" {
  themes: light --default, dark --prefersdark, cupcake, bumblebee, emerald, corporate, synthwave, retro, cyberpunk, valentine, halloween, garden, forest, aqua, lofi, pastel, fantasy, wireframe, black, luxury, dracula, cmyk, autumn, business, acid, lemonade, night, coffee, winter, dim, nord, sunset, caramellatte, abyss, silk;
}
```

- `light --default`: Sets 'light' as the default theme for light mode preference
- `dark --prefersdark`: Sets 'dark' as the automatic theme for dark mode preference (`prefers-color-scheme: dark`)

The HTML layouts do **not** hardcode `data-theme="light"` since daisyUI automatically applies the correct theme based on browser preference.

### Custom Theme Override Logic

The ThemeController only applies custom themes when users have selected non-default preferences:

```javascript
hasCustomThemes() {
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  const expectedDefault = prefersDark ? 'dark' : 'light'
  const currentTheme = this.getCurrentTheme()
  
  return currentTheme && currentTheme !== expectedDefault
}
```

This prevents JavaScript from overriding daisyUI's automatic theme detection unless the user has custom preferences like 'cupcake' for light mode or 'dracula' for dark mode.



## CSS Transitions

The system includes comprehensive CSS transitions to prevent screen flashing during theme changes:

```css
/* Dynamic transition timing controlled by JavaScript */
:root {
  --theme-transition-duration: 0.3s;
}

/* All theme-dependent properties transition smoothly */
*, *::before, *::after {
  transition:
    background-color var(--theme-transition-duration) ease,
    border-color var(--theme-transition-duration) ease,
    color var(--theme-transition-duration) ease,
    /* ... other properties */
}
```

**Transition Speeds:**
- **Hover previews**: 0.15s (fast, responsive feel)
- **Theme selection**: 0.3s (normal, smooth visual change)
- **Accessibility**: Respects `prefers-reduced-motion` setting

## Performance Benefits

The split controller architecture provides significant performance improvements:

**Blog and Dashboard Pages:**
- Load only ThemeController (~40% of original code)
- No UI selection overhead (galleries, hover previews, checkmarks)
- Faster page loads and reduced memory usage

**Settings Page:**
- Uses both controllers with clear separation of concerns
- ThemeController handles core theme logic
- ThemeSelectorController manages UI interactions
- Better maintainability and testing

## Horizontal Gallery Styling

Enhanced styling for the horizontal theme galleries (ThemeSelectorController):

```css
.theme-gallery {
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: thin;
  scrollbar-color: oklch(var(--bc) / 0.3) oklch(var(--bc) / 0.1);
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
}

.theme-card {
  min-width: 80px;
  transition: all 0.2s ease;
}

.theme-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px -5px oklch(var(--bc) / 0.1);
}
```

**Gallery Features:**
- Horizontal scrolling with touch support
- Theme-aware scrollbar colors
- Smooth scroll behavior
- Hover effects with subtle lift animation
- Gradient fade indicators for scroll visibility
- Cross-browser scrollbar compatibility
