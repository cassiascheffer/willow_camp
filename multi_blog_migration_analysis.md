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
- `20250831122011_add_unique_primary_blog_per_user.rb` - Adds unique constraint for primary blogs ✅ NEW

### 2. ✅ COMPLETED - Rake task updates
The following have been completed in `lib/tasks/migrate_users_to_blogs.rake`:
- Sets `primary: true` for the first blog created for each user
- Added dry run mode support
- Added comprehensive logging
- Added rollback safety checks

### 3. Execute rake tasks in order
```bash
# OPTIONAL: Test with dry run first
DRY_RUN=true rails data:migrate_users_to_blogs
DRY_RUN=true rails data:migrate_tags_to_blogs

# Step 1: Migrate user blog data to blogs table
rails data:migrate_users_to_blogs

# Step 2: Verify data integrity
rails data:verify_blog_migration

# Step 3: Migrate tag tenants from user_id to blog_id
rails data:migrate_tags_to_blogs

# Step 4: Verify tag migration
rails data:verify_tag_blog_migration
```

### 4. ⚠️ CRITICAL - Update application code AFTER migration
**This step MUST happen AFTER the data migration is complete:**

1. **Prepare a separate branch** with the Post model change:
   ```ruby
   # In app/models/post.rb line 7
   # Change from:
   acts_as_taggable_tenant :author_id
   # To:
   acts_as_taggable_tenant :blog_id
   ```

2. **Deploy immediately after migration verification**:
   - Do NOT deploy this before data migration (will break tags)
   - Do NOT delay this deployment (tags won't work correctly with new blog structure)
   
3. **Update controllers** to use Blog model instead of User for blog operations (can be in same deployment)

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

### ✅ Completed
1. **Add primary field**: Updated rake task to set `primary: true` for first blog (line 63 in migrate_users_to_blogs.rake)
2. **Rails validation**: Added `only_one_primary_per_user` validation to Blog model
3. **Database constraint**: Added unique partial index on `[user_id, primary]` where `primary = true` (migration 20250831122011)
4. **Rollback safety**: Added comprehensive safety checks and warnings in rollback tasks
5. **Logging**: Added detailed Rails.logger calls for debugging production issues
6. **Dry run mode**: Added DRY_RUN=true option to simulate migrations without making changes

### Still Needed (CRITICAL - Deploy AFTER Migration)
1. **Tag tenant update**: The Post model MUST be updated AFTER the data migration is complete.
   
   **Why this must be done after migration:**
   - Currently, all tags use `author_id` (user ID) as the tenant
   - The migration will change these to use `blog_id` as the tenant
   - If we change the code before migrating data, tags will break (looking for blog_id tenants that don't exist)
   - If we migrate data without changing the code, tags continue working with the old tenant temporarily
   
   **The change required (app/models/post.rb line 7):**
   ```ruby
   # BEFORE (current):
   acts_as_taggable_tenant :author_id
   
   # AFTER (deploy after migration):
   acts_as_taggable_tenant :blog_id
   ```
   
   **Deployment sequence:**
   1. Run data migration (tags still work with author_id)
   2. Verify migration success
   3. Deploy code change to use blog_id
   4. Tags now work with blog_id tenant

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

## Production Migration Checklist

### Phase 1: Pre-migration (Can do now)
- [ ] Backup production database
- [ ] Deploy new migration file: `20250831122011_add_unique_primary_blog_per_user.rb`
- [ ] Run `rails db:migrate` in production
- [ ] Prepare branch with Post model change (do NOT deploy yet)

### Phase 2: Data Migration
- [ ] Run dry run: `DRY_RUN=true rails data:migrate_users_to_blogs`
- [ ] Run dry run: `DRY_RUN=true rails data:migrate_tags_to_blogs`
- [ ] Execute: `rails data:migrate_users_to_blogs`
- [ ] Verify: `rails data:verify_blog_migration`
- [ ] Execute: `rails data:migrate_tags_to_blogs`
- [ ] Verify: `rails data:verify_tag_blog_migration`

### Phase 3: Code Deployment (IMMEDIATELY AFTER Phase 2)
- [ ] Deploy branch with `acts_as_taggable_tenant :blog_id` change
- [ ] Verify tags are working correctly
- [ ] Monitor logs for any issues

## Notes
- Migration maintains backward compatibility during transition
- Old code can still work with user blog fields while new code uses Blog model
- Once migration is complete and verified, user blog fields can be removed in a future cleanup
- **CRITICAL**: The Post model change MUST be deployed after data migration, not before