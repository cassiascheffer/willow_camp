# Social Share Image Generator

This feature automatically generates beautiful social share images for your blog posts using JavaScript and HTML5 Canvas. The images are optimized for social media platforms like LinkedIn, Twitter, and Facebook.

## Features

- **Automatic Generation**: Images are generated client-side when posts are viewed
- **Favicon Integration**: Extracts colors from your favicon emoji to create matching gradients
- **Muted Pastel Colors**: Creates soft, professional-looking gradient backgrounds
- **LinkedIn Optimized**: Images are 1200x627 pixels, meeting LinkedIn's specifications
- **Dynamic Meta Tags**: Automatically updates Open Graph and Twitter Card meta tags
- **Download Support**: Users can download generated images for manual sharing

## How It Works

1. **Color Extraction**: The system renders your favicon emoji on a small canvas and analyzes the pixel data to extract dominant colors
2. **Color Processing**: Dominant colors are converted to muted pastel versions by blending with white and reducing saturation
3. **Gradient Creation**: A diagonal gradient background is created using the extracted pastel colors
4. **Text Rendering**: The post title, author name, and blog title are rendered with proper typography
5. **Meta Tag Injection**: Social media meta tags are dynamically updated with the generated image

## Usage

### Automatic Generation (Recommended)

Social share images are automatically generated for all published posts. Simply include the helper in your post view:

```erb
<%= social_share_image_for(@post) %>
```

### Dashboard Preview

In the dashboard, authors can preview how their posts will appear on social media:

```erb
<%= social_share_image_preview_for(@post) %>
```

This provides:
- Live preview of the generated image
- Regenerate button to create a new version
- Download button to save the image locally

### Manual Implementation

For custom implementations, use the Stimulus controller directly:

```html
<div data-controller="social-share-image" 
     data-social-share-image-title-value="Your Post Title"
     data-social-share-image-author-value="Author Name"
     data-social-share-image-favicon-value="🌟"
     data-social-share-image-blog-title-value="Your Blog">
</div>
```

## Technical Specifications

### Image Dimensions
- **Width**: 1200px
- **Height**: 627px
- **Format**: PNG
- **Aspect Ratio**: 1.91:1 (LinkedIn recommended)

### Typography
- **Title Font**: System UI, bold, responsive sizing (48-80px)
- **Author Font**: System UI, regular, 32px
- **Blog Title Font**: System UI, regular, 24px
- **Text Color**: Dark gray (#1a1a1a for title, #4a4a4a for author)

### Color Processing
- **Extraction**: Analyzes 64x64 pixel canvas of favicon emoji
- **Filtering**: Removes transparent, near-black, and near-white pixels
- **Grouping**: Groups similar colors with 30-point tolerance
- **Pasteling**: Blends with 30% white and reduces saturation by 60%
- **Range**: Ensures colors stay in pastel range (180-255 RGB values)

### Gradient
- **Type**: Linear diagonal gradient
- **Direction**: Top-left to bottom-right (0,0 to 80% width/height)
- **Stops**: 2-3 color stops depending on extracted colors
- **Texture**: Subtle white dot overlay for depth

## Browser Support

- **Modern Browsers**: Full support (Chrome, Firefox, Safari, Edge)
- **Canvas API**: Required for image generation
- **Blob API**: Required for downloads
- **HTML5 Canvas**: Required for color extraction

## Performance Considerations

- **Client-Side**: All processing happens in the browser
- **Caching**: Generated images are cached as data URLs
- **Lazy Loading**: Images generate when the controller connects
- **Memory**: Temporary canvases are cleaned up after use

## Customization

### Styling
The preview component uses CSS classes that can be customized:

```css
.social-share-preview { /* Preview container */ }
.social-share-canvas-container { /* Canvas wrapper */ }
```

### Colors
To modify the fallback colors when emoji extraction fails, edit the controller:

```javascript
// In social_share_image_controller.js
const mutedColors = [
  { r: 255, g: 240, b: 245 }, // Light pink
  { r: 240, g: 248, b: 255 }, // Light blue  
  { r: 245, g: 255, b: 240 }  // Light green
]
```

### Typography
Font sizes and styles can be adjusted in the `addTextContent` method:

```javascript
const titleFontSize = this.calculateTitleFontSize(this.titleValue, width - 120)
ctx.font = `bold ${titleFontSize}px system-ui, -apple-system, sans-serif`
```

## Troubleshooting

### No Colors Extracted
- Ensure favicon emoji renders properly in the browser
- Check that emoji contains sufficient color information
- Verify browser supports Canvas API

### Poor Quality Images
- Increase canvas dimensions (currently 1200x627)
- Adjust font sizes for better readability
- Modify color extraction tolerance values

### Meta Tags Not Updating
- Check that JavaScript is enabled
- Verify Stimulus controller is properly loaded
- Ensure no CSP restrictions on dynamic content

### Download Issues
- Verify browser supports Blob API and download attributes
- Check for popup blockers
- Ensure HTTPS for secure contexts

## Examples

The system works with various favicon emojis:

- 🌟 → Gold and yellow pastels
- 🌺 → Pink and magenta pastels  
- 🌊 → Blue and teal pastels
- 🍃 → Green and mint pastels
- ⛺ → Brown and orange pastels (default)

Each emoji produces a unique gradient that matches the blog's visual identity while maintaining excellent readability for social sharing.