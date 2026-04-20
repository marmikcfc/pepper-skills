---
name: aviato-linkedin-activity
description: Get LinkedIn posts and social activity for people and companies using Aviato. Use when asked to see someone's LinkedIn posts, check a company's LinkedIn activity, or monitor social presence.
---

# Aviato LinkedIn Activity

Pull LinkedIn posts for people and companies, plus engagement data on individual posts.

## Company LinkedIn Posts

Use the company's LinkedIn string ID (the slug from their LinkedIn URL):

```bash
orth run aviato /social/company/posts -q 'linkedinID=stripe' -q 'perPage=10'
```

```bash
orth run aviato /social/company/posts -q 'linkedinID=google' -q 'perPage=5'
```

## Person's LinkedIn Posts

Use the person's LinkedIn username:

```bash
orth run aviato /social/person/posts -q 'linkedinID=satyanadella' -q 'perPage=10'
```

If you don't know the linkedinID, enrich the person first:

```bash
orth run aviato /person/enrich -q 'linkedinURL=https://www.linkedin.com/in/satyanadella'
```

Look for `linkedinID` in the response, then use it above.

## Post Comments

Use the post `urn` from the posts response (e.g., `urn:li:ugcPost:7444736439218515968`):

```bash
orth run aviato '/social/post/urn:li:ugcPost:7444736439218515968/comments' -q 'page=1' -q 'perPage=20'
```

Returns each comment with commenter name, LinkedIn profile, text, reactions, and timestamp.

## Post Reactions

```bash
orth run aviato '/social/post/urn:li:ugcPost:7444736439218515968/reactions' -q 'page=1' -q 'perPage=20'
```

Returns each reactor with name, headline, LinkedIn IDs, and reaction type (LIKE, PRAISE, EMPATHY, etc.).

## Post Reshares

```bash
orth run aviato '/social/post/urn:li:ugcPost:7444736439218515968/reshares' -q 'page=1' -q 'perPage=20'
```

## Workflow: Analyze a Company's LinkedIn Presence

1. Pull recent posts:
   ```bash
   orth run aviato /social/company/posts -q 'linkedinID=anthropic' -q 'perPage=10'
   ```
2. Identify high-engagement posts from the `socialActivityCounts` in each result
3. Drill into top posts for comments and reactions:
   ```bash
   orth run aviato '/social/post/POST_URN/comments' -q 'page=1' -q 'perPage=20'
   ```

## Pagination

All social endpoints support `page` and `perPage` query params.
