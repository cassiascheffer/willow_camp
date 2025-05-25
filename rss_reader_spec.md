# RSS Reader Functionality Specification

## Overview
Add an RSS reader feature to Willow Camp, allowing users to subscribe to and read RSS feeds. This feature will become the primary dashboard view, with the existing blogging functionality moved to a separate menu item.

## Core Features

### Phase 1: Initial Implementation
1. **Feed Management**
   - Add feeds by URL directly
   - Import feeds via OPML file
   - Manual refresh of feeds
   - List view of subscribed feeds

2. **Feed Reading**
   - View all unread items across feeds in chronological order
   - View items from a specific feed
   - Mark items as read/unread
   - Display for each item:
     - Title
     - Image (if available)
     - Website/feed title
     - Excerpt/summary
     - Link to original article
   - Option to show/hide read items
   - Automatically prune feed items after 30 days

3. **UI Integration**
   - Make the RSS reader the default dashboard view
   - Move blogging functionality to a separate menu item
   - Maintain consistent styling with the rest of the application

### Phase 2: Future Enhancements
1. **Feed Organization**
   - Add category support for feeds
   - Filter unread items by category
   
2. **Additional Features** (for future consideration)
   - Bookmarking/saving items for later
   - Search functionality within feeds
   - Automatic background refresh
   - Feed discovery by topic/name

## Database Schema

### New Tables

#### `feed_subscriptions`
| Column | Type | Description |
|--------|------|-------------|
| `id` | integer | Primary key |
| `user_id` | integer | Foreign key to users table |
| `title` | string | User-defined title for the feed |
| `url` | string | URL of the feed |
| `site_url` | string | URL of the source website |
| `description` | text | Description of the feed |
| `favicon_url` | string | URL to favicon image |
| `last_fetched_at` | datetime | When the feed was last updated |
| `created_at` | datetime | When the subscription was created |
| `updated_at` | datetime | When the subscription was last updated |
| `feed_items_count` | integer | Counter cache for feed items |
| `unread_items_count` | integer | Counter cache for unread items |
| `status` | string | Status of the feed (active, error, etc.) |
| `error_message` | text | Last error message if feed fetching failed |
| `category_id` | integer | Foreign key to feed_categories (Phase 2) |

#### `feed_items`
| Column | Type | Description |
|--------|------|-------------|
| `id` | integer | Primary key |
| `feed_subscription_id` | integer | Foreign key to feed_subscriptions |
| `title` | string | Title of the feed item |
| `url` | string | URL to the original content |
| `author` | string | Author of the content |
| `content` | text | HTML content if available |
| `summary` | text | Plain text summary/excerpt |
| `published_at` | datetime | When the item was published |
| `guid` | string | Unique identifier from the feed |
| `image_url` | string | URL to featured image if available |
| `read` | boolean | Whether the user has read the item |
| `created_at` | datetime | When the item was added to the database |
| `updated_at` | datetime | When the item was last updated |

#### `feed_categories` (Phase 2)
| Column | Type | Description |
|--------|------|-------------|
| `id` | integer | Primary key |
| `user_id` | integer | Foreign key to users table |
| `name` | string | Name of the category |
| `created_at` | datetime | When the category was created |
| `updated_at` | datetime | When the category was last updated |

## Model Relationships

```ruby
# User
has_many :feed_subscriptions, dependent: :destroy
has_many :feed_categories, dependent: :destroy # Phase 2

# FeedSubscription
belongs_to :user
belongs_to :category, optional: true # Phase 2
has_many :feed_items, dependent: :destroy

# FeedItem
belongs_to :feed_subscription
scope :unread, -> { where(read: false) }
scope :recent, -> { order(published_at: :desc) }
scope :prunable, -> { where('published_at < ?', 30.days.ago) }

# FeedCategory (Phase 2)
belongs_to :user
has_many :feed_subscriptions
```

## Routes

```ruby
namespace :dashboard do
  resources :feeds do
    collection do
      post :import_opml
      get :export_opml
    end
    
    member do
      post :refresh
    end
    
    resources :items, only: [:index, :show] do
      member do
        post :toggle_read
      end
      collection do
        post :mark_all_read
        get :unread
      end
    end
  end
  
  resources :feed_categories, except: [:show] # Phase 2
  
  # Existing blog post routes moved here but preserved
  resources :posts, except: [:index, :show], param: :slug
end
```

## Controllers

### Required Controllers:
1. `Dashboard::FeedsController` - Managing feed subscriptions
2. `Dashboard::FeedItemsController` - Viewing and interacting with feed items
3. `Dashboard::FeedCategoriesController` - Managing categories (Phase 2)

## Services

### New Service Classes:
1. `FeedFetcher` - Fetch and parse RSS feeds
2. `OPMLImporter` - Import feeds from OPML files
3. `OPMLExporter` - Export feeds to OPML format
4. `FeedItemPruner` - Remove old feed items

## UI/UX

### Dashboard Layout Changes
- Update main navigation to prioritize RSS reader functionality
- Move blog management to a separate navigation item
- Design new feed listing page
- Design feed item reading view

### New Views
1. Feed subscription list
2. Feed detail view with items
3. All items view (across feeds)
4. Feed import/export interface
5. Feed categories management (Phase 2)

## Implementation Plan

### Phase 1: Core RSS Reader
1. Create database migrations for `feed_subscriptions` and `feed_items`
2. Implement models with relationships and validations
3. Create service objects for fetching and parsing feeds
4. Build controllers for managing feeds and items
5. Design and implement UI for the RSS reader
6. Implement OPML import/export
7. Set up scheduled job for pruning old items
8. Update dashboard navigation and layout

### Phase 2: Categories and Organization
1. Create migration for `feed_categories`
2. Update models to support categories
3. Enhance controllers to filter by category
4. Update UI to display and manage categories
5. Allow assignment of feeds to categories

## Dependencies

- RSS/Atom parsing library (e.g., Feedjira)
- OPML parsing/generating library
- HTTP client for fetching feeds (e.g., HTTParty or Faraday)
- Background job processing for feed fetching and pruning (using existing Solid Queue)

## Testing

- Unit tests for models and services
- Controller tests for user interactions
- System tests for critical user flows
- Testing feeds with various formats and edge cases

## Performance Considerations

- Implement counter caches to avoid expensive counts
- Consider batched background processing for feed updates
- Pagination for feed items
- Proper indexing for feed_items table
- Optimize feed parsing for memory usage
