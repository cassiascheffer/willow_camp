## API Documentation

The API uses token-based authentication and returns JSON responses.

### Authentication

Include a bearer token in requests:

```
Authorization: Bearer your-api-token
```

Create tokens in the dashboard at `/dashboard/settings`.

### Endpoints

#### List Posts

```
GET /api/posts
```

Returns all posts for the authenticated user.

**Response:**
```json
{
  "posts": [
    {
      "id": 1,
      "slug": "my-post",
      "markdown": "---\ntitle: My Post\n---\n# Content"
    }
  ]
}
```

#### Get a Post

```
GET /api/posts/:slug
```

Returns a specific post by slug.

#### Create a Post

```
POST /api/posts
```

**Request:**
```json
{
  "post": {
    "markdown": "---\ntitle: My New Post\npublished: true\n---\n# Content"
  }
}
```

#### Update a Post

```
PATCH /api/posts/:slug
```

**Request:**
```json
{
  "post": {
    "markdown": "---\ntitle: Updated Title\n---\n# Updated content"
  }
}
```

#### Delete a Post

```
DELETE /api/posts/:slug
```

Returns 204 on success.

### Error Responses

- **401**: `{ "error": "Unauthorized" }`
- **403**: `{ "error": "You don't have permission to access this post" }`
- **404**: `{ "error": "Post not found" }`
- **422**: `{ "errors": ["Title can't be blank"] }`

### Example Usage

```bash
curl -X POST https://willow.camp/api/posts \
  -H "Authorization: Bearer your-api-token" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "markdown": "---\ntitle: API Post\n---\n# Hello World"
    }
  }'
```

## Markdown Posts

Posts use Markdown with YAML frontmatter:

```yaml
---
title: My Post
description: Post description
published: true
date: 2023-05-25
tags:
  - rails
  - ruby
---

# Post content

Regular markdown content here.
```

### Creating Posts from Files

```ruby
markdown_content = File.read("path/to/post.md")
author = User.find_by(email: "author@example.com")
post = Post.from_markdown(markdown_content, author)
post.save
```
