# Search Console, indexing, and social metadata

The termr documentation site is a GitHub Pages project site at
<https://menshikovs.github.io/termr/>. Its pkgdown configuration sets that
publication URL. pkgdown generates `sitemap.xml` during the site build and
uses the configured homepage title and description on the homepage. Reference
pages use their documented topic titles and descriptions. The site's Open
Graph card uses the existing widget showcase image.

pkgdown's standard Bootstrap 5 template appends ` • termr` to page titles.
`home.title` omits the package name so the homepage title reads
`Reactive Terminal UI Framework for R • termr`, with the name appearing once.
The template has no configuration switch to remove this suffix; the title
template remains unchanged.

The homepage content comes from `pkgdown/index.md`, not `README.md`.
Website-only tutorials live in `vignettes/articles/`; they are excluded from
R package builds and execute their headless examples during the pkgdown build.
The existing GitHub Actions workflow runs `tools/build-site.R` to build `site/` and deploys that directory
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

## Bing Webmaster Tools verification

The supplied `BingSiteAuth.xml` is retained unchanged at
`pkgdown/assets/BingSiteAuth.xml`; pkgdown publishes it at
<https://menshikovs.github.io/termr/BingSiteAuth.xml>. The Bing meta tag is
configured through pkgdown's supported `template.includes.in_header` setting
and appears in each generated page's `<head>`:

```html
<meta name="msvalidate.01" content="ED124DAA8CF210E4D6CB70008D1A15B1" />
```

Keep the supplied tag and file unchanged after verification. Both methods can
coexist. pkgdown's native sitemap lists HTML pages; the XML verification file
is published at the site root for Bing to fetch directly and is not a sitemap
page. See Bing's
[site ownership verification guide](https://www.bing.com/webmasters/help/add-and-verify-site-12184f8b?action=learn&source=helpdocvnext&type=verificationtrouble).

## Local build and indexing checks

With pkgdown, its website dependencies and Pandoc available, run:

```sh
Rscript tools/build-site.R
```

This command builds locally; it does not deploy. Inspect `site/index.html`
for both verification tags, title, description, and Open Graph image. Check the
three tutorial pages under `site/articles/` and their entries in
`site/sitemap.xml`. The preview image is copied from
`pkgdown/assets/widget-showcase.png` to the site root; keep it synchronized
with the existing `docs/images/widget-showcase.png` screenshot if replaced.
Generated `site/` files are ignored by Git.

Run `Rscript tools/validate-site-seo.R` after the build to check metadata,
local links, image and verification-file integrity, and sitemap URLs.

pkgdown 2.2.1's Bootstrap 5 template does not emit canonical link elements or
`og:url` on normal content pages, and does not expose each output path to its
header templates. After the standard pkgdown build, `tools/build-site.R` uses
the native sitemap to add both URLs to content pages. The homepage points to
the public site root; every other content page points to its own absolute URL.
Existing URL tags are checked for conflicts rather than overwritten. Redirect
pages retain their canonical destinations and intentional `noindex` directives;
verification assets remain unchanged. The sitemap is not rewritten.

A read-only public URL check on 2026-10-20 found that `/termr/` and
`/termr/index.html` both returned HTTP 200 with identical HTML; `/termr`
redirected to `/termr/`. These homepage aliases already exist on the published
site. The native sitemap lists only `index.html`, and generated home links
use that path; both now declare the site root as canonical after deployment.
Inspect both URLs in Search Console and
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

## Structured data and social sharing

`tools/build-site.R` calls the existing `pkgdown::build_site_github_pages()`
entry point. It reads `DESCRIPTION` at build time and passes structured data
through pkgdown's configuration override to the small
`pkgdown/templates/in-header.html` partial. The JSON-LD describes the package
as Schema.org `SoftwareSourceCode`, using the actual version, author names and
first sentence of the package description. The license URL identifies MIT,
matching `DESCRIPTION` and `LICENSE`; the build checks that declaration so a
future license change requires updating this mapping. It adds no runtime
dependencies. Use the build script locally as well as in CI to include all
metadata; invoking pkgdown directly bypasses this integration.

The partial preserves `template.includes.in_header` (including Bing ownership
verification) and pkgdown's native page-specific Open Graph title, description
and image. It adds site name, type, English locale and Twitter title,
description and image. Pages without a description receive the concise
package description as a fallback. With the existing widget screenshot,
Twitter uses `summary_large_image`; no unverified social account is specified.
The partial defers to a native Twitter card if one is configured later.
The existing 1105 by 577 pixel image at `pkgdown/assets/widget-showcase.png` is published at
<https://menshikovs.github.io/termr/widget-showcase.png>; no new image is needed.

Concise keywords live in `_pkgdown.yml`. They describe the package and make no
ranking guarantees. `tools/validate-site-seo.R` checks every sitemap content
page for valid JSON-LD, source metadata, matching social tags, unique metadata,
page-specific URLs and existing image assets. Native redirects and ownership
verification files are checked separately. The design and navigation templates
remain unchanged. See pkgdown's [metadata guide](https://pkgdown.r-lib.org/articles/metadata.html)
and [template includes documentation](https://pkgdown.r-lib.org/articles/customise.html#additional-html-and-files).

## Owner steps in Bing Webmaster Tools

These steps require access to the owner's Microsoft account. Repository
changes can publish the sitemap and verification methods, but cannot add the
property or complete verification. Bing also offers importing a site from
Google Search Console when the account can access that property.

1. Open <https://www.bing.com/webmasters/> and add the URL-prefix property
   `https://menshikovs.github.io/termr/`.
2. Choose HTML meta tag or XML file verification. For the meta tag, confirm the
   displayed value is `ED124DAA8CF210E4D6CB70008D1A15B1`. For XML verification,
   confirm Bing's supplied file is `BingSiteAuth.xml` and its contents match
   the retained file. If Bing supplies different verification data, use that
   actual token or file and update the repository before verifying.
3. Merge the documentation change to `main` and wait for the existing Pages
   deployment. Confirm the meta tag in page source or open
   <https://menshikovs.github.io/termr/BingSiteAuth.xml> and compare its
   contents with Bing's supplied file. Then complete verification in Bing.
4. Submit `https://menshikovs.github.io/termr/sitemap.xml` in Bing Webmaster
   Tools. Optionally inspect the homepage and important tutorials.
5. Review indexing and search performance reports later. Local checks cannot
   confirm ownership or indexing; discovery and rankings are not guaranteed.
