# Search Console and indexing

The termr documentation site is a GitHub Pages project site at
<https://menshikovs.github.io/termr/>. Its pkgdown configuration sets that
publication URL. pkgdown generates `sitemap.xml` during the site build and
uses the configured homepage title and description on the homepage. Reference
pages use their documented topic titles and descriptions. The site's Open
Graph card uses the existing widget showcase image.

pkgdown's standard Bootstrap 5 template appends ` • termr` to page titles.
`home.title` omits the package name so the homepage title reads
`Reactive Terminal UI Framework for R • termr`, with the name appearing once.
The template has no configuration switch to remove this suffix; no custom
template override is used.

The homepage content comes from `pkgdown/index.md`, not `README.md`.
Website-only tutorials live in `vignettes/articles/`; they are excluded from
R package builds and execute their headless examples during the pkgdown build.
The existing GitHub Actions workflow builds `site/` and deploys that directory
to `gh-pages` on pushes to `main`. No separate SEO publishing step is needed.

## Retained ownership verification

`_pkgdown.yml` uses pkgdown's supported `template.params.google_site_verification`
setting. It renders this element once in the generated page head:

```html
<meta name="google-site-verification" content="y-1CU_OpfbxmAGDGQm3qi8Xc9RcalnzCOzJ3CZ2VA_o" />
```

Keep the tag after verification so Google can recheck ownership. Do not add a
second copy through a header include. See the
[pkgdown configuration reference](https://pkgdown.r-lib.org/reference/build_site.html#other-aspects).

The supplied Google verification file is also kept at
`pkgdown/assets/google9c54d79139c77170.html`. pkgdown copies files from
`pkgdown/assets/` to the root of the generated site, so the file is published
as `/termr/google9c54d79139c77170.html` by the existing deployment workflow.
Do not edit its filename or contents. Both methods can coexist. If an owner
needs another verification file, retain this file and add the actual new file
supplied by Google.

## Local build and indexing checks

With pkgdown, its website dependencies and Pandoc available, run:

```r
pkgdown::build_site_github_pages(
  dest_dir = "site", new_process = FALSE, install = FALSE
)
```

This command builds locally; it does not deploy. Inspect `site/index.html`
for one verification tag, title, description, and Open Graph image. Check the
three tutorial pages under `site/articles/` and their entries in
`site/sitemap.xml`. The preview image is copied from
`pkgdown/assets/widget-showcase.png` to the site root; keep it synchronized
with the existing `docs/images/widget-showcase.png` screenshot if replaced.
Generated `site/` files are ignored by Git.

Run `Rscript tools/validate-site-seo.R` after the build to check metadata,
local links, image and verification-file integrity, and sitemap URLs.

pkgdown 2.2.1's Bootstrap 5 template does not emit canonical link elements or
`og:url` on normal content pages. The configured `url` supplies absolute
sitemap and social-image URLs. Do not add a site-wide homepage canonical to
every page: article and reference URLs must remain distinct. Redirect pages
have their own canonical destinations and intentional `noindex` directives.

A read-only public URL check on 2026-10-20 found that `/termr/` and
`/termr/index.html` both returned HTTP 200 with identical HTML; `/termr`
redirected to `/termr/`. These homepage aliases already exist on the published
site. The native sitemap lists only `index.html`, and generated home links
use that path. After deployment, inspect both URLs in Search Console and
compare **Google-selected canonical** in the page indexing details. A local
build cannot determine Google's choice or confirm that Google has consolidated
the aliases. See Google's
[canonical URL guidance](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls).

The native sitemap excludes pkgdown's reference redirects, but includes
`404.html` and the Google verification HTML asset. There is no configurable
exclusion in the installed sitemap builder. Keep native generation rather
than editing its output; these two entries do not guarantee indexing.

## robots.txt limitation

This repository does not publish a `robots.txt`. Google expects that file at
the top level of the host, `https://menshikovs.github.io/robots.txt`. A file
at `/termr/robots.txt` is below the host root and cannot control crawling for
the termr project site. The host root belongs to the account-level
`menshikovs.github.io` Pages site, so any host-wide robots policy must be
managed there. Google treats paths in robots rules relative to the host root.
See Google's [robots.txt location and scope](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec#file-location-and-range-of-validity).

## Owner steps in Google Search Console

These steps require access to the owner's Google account. Repository changes
can publish the site, sitemap, and verification asset, but cannot add the
property or complete verification in Search Console.

Google documents both retained methods in its
[ownership verification guide](https://support.google.com/webmasters/answer/9008080?hl=en).

1. Open <https://search.google.com/search-console/> and choose **Add property**.
2. Select **URL prefix** and enter exactly
   `https://menshikovs.github.io/termr/`.
3. Choose **HTML tag** verification and confirm the supplied token matches
   the value above. A different account/property may supply a different token;
   use the actual value Google supplies.
4. After reviewing and committing locally, merge the documentation change to
   `main`. The existing pkgdown workflow
   builds the site and deploys the `site/` directory to `gh-pages` on a push
   to `main`. Wait for that workflow to finish successfully.
5. Open <https://menshikovs.github.io/termr/> and use **View page source**.
   Confirm the exact `google-site-verification` element appears in `<head>`
   once, then return to Search Console and click **Verify**. Alternatively,
   use **HTML file** verification if Google supplies the retained file and
   confirm <https://menshikovs.github.io/termr/google9c54d79139c77170.html>
   is publicly accessible with its exact verification contents.
6. In the verified URL-prefix property, open **Sitemaps** and submit
   `https://menshikovs.github.io/termr/sitemap.xml`.
7. Use **URL inspection** for `https://menshikovs.github.io/termr/`, run a
   live test, and choose **Request indexing** if available. Repeat for
   `articles/getting-started.html`, `articles/terminal-dashboards.html` and
   `articles/testing-terminal-ui.html` under that URL prefix.
8. Later, review **Pages** (indexing status) and **Performance** (search
   impressions, clicks, queries, and pages). Indexing and search visibility
   are not guaranteed, and updates can take time to appear.

Monitor branded queries such as `termr`, `termr R` and `termr R package`, plus
use-case queries such as `R TUI framework`, `R terminal user interface`,
`R terminal dashboard` and `testing terminal UI applications in R`. Compare
impressions and indexed pages over time; local validation cannot establish
Google indexing, ranking or Search Console ownership.
