# Discourse Static Site

Deploy pre-built static sites from HTTPS Git repositories into Discourse at
`/pages/<slug>`. The Discourse header, sidebar, and footer remain visible while
the site runs in a sandboxed, automatically-sized iframe.

## Use

1. Enable `discourse static site enabled` in site settings.
2. Open **Admin → Plugins → Static sites**.
3. Add a display name, route slug, branch, and repository URL. Private repository
   URLs may use `https://<token>@host/owner/repo.git`.
4. Click **Deploy**, then **Refresh** to see the background job result.

The repository root must contain `index.html`, contain no symlinks, and stay
within the configured size limit after checkout. Root-relative asset and route
URLs are automatically scoped to the deployed site. Missing paths fall back to
`index.html` for SPA routing.

## Scope

This first version supports one Discourse site on one web container. Deployments
are manual, use local temporary storage, and are not included in Discourse
backups. Git LFS, submodules, history, automatic rollback, and access controls
are intentionally omitted.
