# Multi-Blog Migration Analysis

## Overview
Analysis of rake tasks for migrating from single-blog to multi-blog system. Production is running commit `290f2372` which does not have any multi-blog functionality.

## Current Issues Found

### 1. Missing `primary` field handling
- The `migrate_users_to_blogs.rake` task doesn't set the `primary` field for blogs
- This field was added in migration `20250823183627_add_primary_to_blogs.rb`
- Each user's first/main blog should be marked as `primary: true`

### 2. About page handling (OK)
- The task correctly uses `insert_all` to bypass callbacks (lines 33-49)
- This avoids duplicate About pages since Blog model has `after_create_commit :ensure_about_page`
- Current implementation is correct

### 3. Tag tenant migration issue
- The tag migration task migrates tenants from `user.id` to `blog.id`
- Post model currently has `acts_as_taggable_tenant :author_id`
- After migration, this needs to change to `:blog_id`

## Migration Steps Required

### 1. Run database migrations first
Ensure all migrations are applied in production:
- `20250823114320_create_blogs.rb` - Creates blogs table
- `20250823115842_add_blog_to_posts.rb` - Adds blog_id to posts
- `20250823121947_update_posts_unique_constraint.rb` - Updates unique constraints
- `20250823183627_add_primary_to_blogs.rb` - Adds primary field to blogs

### 2. Update the rake task
Fix the following in `lib/tasks/migrate_users_to_blogs.rake`:
- Set `primary: true` for the first blog created for each user
- Ensure backward compatibility is maintained
- Add to line 35 in the `insert_all` hash: `primary: true`

### 3. Execute rake tasks in order
```bash
# Step 1: Migrate user blog data to blogs table
rails data:migrate_users_to_blogs

# Step 2: Verify data integrity
rails data:verify_blog_migration

# Step 3: Migrate tag tenants from user_id to blog_id
rails data:migrate_tags_to_blogs

# Step 4: Verify tag migration
rails data:verify_tag_blog_migration
```

### 4. Update application code after migration
After successful migration, update the codebase:
- Change `acts_as_taggable_tenant :author_id` to `acts_as_taggable_tenant :blog_id` in Post model
- Update controllers to use Blog model instead of User for blog operations
- Deploy the updated application code

## Data Being Migrated

### User fields → Blog fields mapping
- `user.subdomain` → `blog.subdomain`
- `user.blog_title` → `blog.title`
- `user.slug` → `blog.slug`
- `user.site_meta_description` → `blog.meta_description`
- `user.favicon_emoji` → `blog.favicon_emoji`
- `user.custom_domain` → `blog.custom_domain`
- `user.theme` → `blog.theme`
- `user.post_footer_markdown` → `blog.post_footer_markdown`
- `user.post_footer_html` → `blog.post_footer_html`
- `user.no_index` → `blog.no_index`

### Post/Page associations
- Posts: `author_id` (stays) + `blog_id` (added)
- Pages: `author_id` (stays) + `blog_id` (added)
- Both inherit from Post model (STI - Single Table Inheritance)

### Tag tenants
- Current: Tags are scoped by `author_id` (user)
- After migration: Tags should be scoped by `blog_id`

## Recommended Fixes

### High Priority
1. **Add primary field**: Update rake task to set `primary: true` for first blog
2. **Tag tenant update**: Ensure Post model is updated to use `blog_id` as tenant after migration

### Medium Priority
1. **Validation**: Add model validation to ensure only one primary blog per user
2. **Rollback safety**: Add additional checks in rollback tasks to prevent data loss
3. **Progress tracking**: Consider adding progress bars for large datasets

### Low Priority
1. **Logging**: Add more detailed logging for debugging production issues
2. **Dry run mode**: Add option to simulate migration without making changes

## Rollback Plan
Both rake tasks include rollback functionality:
- `rails data:rollback_blog_migration` - Removes blogs and clears blog_id from posts
- `rails data:rollback_tag_blog_migration` - Restores user IDs as tag tenants

**WARNING**: Rollback will lose any data added after migration (new blogs, posts in secondary blogs, etc.)

## Testing Recommendations

### Before Production Migration
1. Backup production database
2. Test migration on staging environment with production data copy
3. Verify all user flows work with new multi-blog structure
4. Test rollback procedures

### After Migration Verification
1. Check all users have at least one blog
2. Verify all posts/pages have blog_id set
3. Confirm tags are properly scoped to blogs
4. Test subdomain routing for each blog
5. Verify custom domains still work

## Notes
- Migration maintains backward compatibility during transition
- Old code can still work with user blog fields while new code uses Blog model
- Once migration is complete and verified, user blog fields can be removed in a future cleanup