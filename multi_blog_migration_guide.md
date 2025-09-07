# Multi-Blog System Migration Guide

## Current State
Production is running commit `290f2372` without multi-blog functionality. This guide details the exact steps needed to migrate to the multi-blog architecture.

## Migration Overview
The migration transforms the system from single-blog-per-user to multi-blog-per-user:
- User blog fields → Blog model records
- Post associations → Blog associations  
- Tag tenants → Blog-based scoping

## Pre-Migration Checklist

### 1. Database Backup
```bash
# Create production database backup
pg_dump production_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2. Deploy Database Migrations
Deploy these migration files to production (already exist in codebase):
- `20250823114320_create_blogs.rb` - Creates blogs table
- `20250823115842_add_blog_to_posts.rb` - Adds blog_id to posts  
- `20250823121947_update_posts_unique_constraint.rb` - Updates unique constraints
- `20250823183627_add_primary_to_blogs.rb` - Adds primary field
- `20250831122011_add_unique_primary_blog_per_user.rb` - Ensures one primary blog per user

```bash
# Run migrations in production
rails db:migrate RAILS_ENV=production
```

## Phase 1: Data Migration

### Step 1: Test with Dry Run
```bash
# Simulate blog migration without changes
DRY_RUN=true rails data:migrate_users_to_blogs RAILS_ENV=production

# Simulate tag migration without changes  
DRY_RUN=true rails data:migrate_tags_to_blogs RAILS_ENV=production
```

### Step 2: Execute Blog Migration
```bash
# Migrate user data to blogs table
rails data:migrate_users_to_blogs RAILS_ENV=production
```

This task:
- Creates one blog per user with `primary: true`
- Copies all blog-related fields from User to Blog
- Associates all posts/pages with the new blog via `blog_id`
- Uses `insert_all` to bypass callbacks (prevents duplicate About pages)

### Step 3: Verify Blog Migration
```bash
rails data:verify_blog_migration RAILS_ENV=production
```

Expected output:
```
✅ All verification checks passed!
  - All users have associated blogs
  - All posts have blog_id set
  - All pages have blog_id set
  - User and blog subdomains match
  - User and blog custom domains match
```

### Step 4: Execute Tag Migration
```bash
# Migrate tag tenants from user_id to blog_id
rails data:migrate_tags_to_blogs RAILS_ENV=production
```

This task:
- Updates all tagging records to use `blog_id` as tenant
- Preserves all existing tag relationships
- Maintains tag counts and associations

### Step 5: Verify Tag Migration
```bash
rails data:verify_tag_blog_migration RAILS_ENV=production
```

Expected output:
```
✅ All verification checks passed!
  - All taggings are using blog IDs as tenants
  - No orphaned tenant IDs found
  - Ready to switch application code to use blog tenant
```

## Phase 2: Code Deployment (CRITICAL - IMMEDIATELY AFTER PHASE 1)

### Required Code Change
After data migration succeeds, deploy this single critical change:

**File: `app/models/post.rb` (line 7)**
```ruby
# BEFORE (current production):
acts_as_taggable_tenant :author_id

# AFTER (deploy immediately after migration):
acts_as_taggable_tenant :blog_id
```

### Why Timing Matters
- **Before migration**: Tags use `author_id` (user ID) as tenant
- **During migration**: Data is converted to use `blog_id` as tenant
- **After deployment**: Code uses `blog_id` to match migrated data

⚠️ **WARNING**: Deploying the code change before data migration will break all tags!

### Deployment Command
```bash
# Deploy the code change immediately after successful migration
git checkout multi-blog-post-model
git merge main  # Ensure latest changes
kamal deploy
```

## Phase 3: Post-Migration Verification

### 1. Test Core Functionality
```ruby
# Rails console verification
rails console -e production

# Check blog creation
User.find_each { |u| puts "#{u.email}: #{u.blogs.count} blogs, primary: #{u.blogs.primary.present?}" }

# Check post associations
Post.where(blog_id: nil).count  # Should be 0

# Check tag tenants
ActsAsTaggableOn::Tagging.where(tenant: User.ids).count  # Should be 0
ActsAsTaggableOn::Tagging.where(tenant: Blog.ids).count  # Should match total taggings
```

### 2. Test User-Facing Features
- [ ] Blog subdomain access (e.g., `username.willow.camp`)
- [ ] Custom domain routing (if configured)
- [ ] Post creation and editing
- [ ] Tag functionality (adding, removing, filtering)
- [ ] Page management (About page exists)

### 3. Monitor Logs
```bash
# Watch for errors
tail -f log/production.log | grep -E "(ERROR|FATAL|BlogMigration|TagMigration)"
```

## Rollback Plan (Emergency Only)

⚠️ **WARNING**: Rollback will lose any data created after migration!

### If Migration Fails Before Code Deployment
```bash
# Rollback tag migration first
rails data:rollback_tag_blog_migration RAILS_ENV=production

# Then rollback blog migration
rails data:rollback_blog_migration RAILS_ENV=production
```

### If Issues Occur After Code Deployment
1. Revert code deployment first:
   ```bash
   git revert HEAD  # Revert the blog_id tenant change
   kamal deploy
   ```

2. Then rollback data:
   ```bash
   rails data:rollback_tag_blog_migration RAILS_ENV=production
   rails data:rollback_blog_migration RAILS_ENV=production
   ```

## Migration Summary

### Data Field Mappings
| User Field | → | Blog Field |
|------------|---|------------|
| `subdomain` | → | `subdomain` |
| `blog_title` | → | `title` |
| `slug` | → | `slug` |
| `site_meta_description` | → | `meta_description` |
| `favicon_emoji` | → | `favicon_emoji` |
| `custom_domain` | → | `custom_domain` |
| `theme` | → | `theme` |
| `post_footer_markdown` | → | `post_footer_markdown` |
| `post_footer_html` | → | `post_footer_html` |
| `no_index` | → | `no_index` |

### New Associations
- User `has_many :blogs`
- Blog `belongs_to :user`
- Blog `has_many :posts`
- Post `belongs_to :blog`
- Tags scoped by `blog_id` (after code deployment)

### Key Features of Migration
- ✅ Sets `primary: true` for first blog
- ✅ Prevents duplicate About pages via `insert_all`
- ✅ Comprehensive dry-run mode for testing
- ✅ Detailed logging for debugging
- ✅ Safe rollback procedures
- ✅ Data integrity verification

## Timeline Estimate
- **Phase 1 (Data Migration)**: 10-15 minutes
- **Phase 2 (Code Deployment)**: 5 minutes
- **Phase 3 (Verification)**: 10-15 minutes
- **Total**: ~30-35 minutes

## Support Commands

### Debug Helpers
```ruby
# Find users with multiple blogs (future state)
User.joins(:blogs).group("users.id").having("COUNT(blogs.id) > 1")

# Check tag distribution
Blog.find_each do |blog|
  tag_count = ActsAsTaggableOn::Tagging.where(tenant: blog.id).count
  puts "Blog #{blog.subdomain}: #{tag_count} tags"
end

# Verify post-blog associations
Post.includes(:blog, :author).find_each do |post|
  puts "Post #{post.id}: Author #{post.author_id}, Blog #{post.blog_id}"
end
```

### Production Rails Console
```bash
# Connect to production console
rails console -e production

# Or via Kamal
kamal app exec -i 'rails console'
```

## Contact for Issues
If any issues arise during migration:
1. Check logs: `tail -f log/production.log`
2. Review this guide's rollback procedures
3. Document any errors with full stack traces

## Final Notes
- The migration maintains backward compatibility during transition
- User blog fields remain populated (can be removed in future cleanup)
- The system supports future multi-blog functionality per user
- All existing URLs and routes continue to work