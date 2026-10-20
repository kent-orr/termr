# Search Console and indexing

The termr documentation site is a GitHub Pages project site at
<https://menshikovs.github.io/termr/>. Its pkgdown configuration sets that
canonical site URL. pkgdown generates `sitemap.xml` during the site build and
uses the configured homepage title and description on the homepage. Reference
pages use their documented topic titles and descriptions. The site's Open
Graph card uses the existing widget showcase image.

The supplied Google verification file is kept at
`pkgdown/assets/google9c54d79139c77170.html`. pkgdown copies files from
`pkgdown/assets/` to the root of the generated site, so the file is published
as `/termr/google9c54d79139c77170.html` by the existing deployment workflow.
Do not edit its filename or contents. If Search Console provides a different
verification file, replace this asset with that exact downloaded file.

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

1. Open <https://search.google.com/search-console/> and choose **Add property**.
2. Select **URL prefix** and enter exactly
   `https://menshikovs.github.io/termr/`.
3. Choose **HTML file** verification. Confirm Search Console supplies the
   `google9c54d79139c77170.html` file already stored in `pkgdown/assets/`.
   If it supplies another file, replace the asset as described above.
4. Merge the documentation change to `main`. The existing pkgdown workflow
   builds the site and deploys the `site/` directory to `gh-pages` on a push
   to `main`. Wait for that workflow to finish successfully.
5. Open
   <https://menshikovs.github.io/termr/google9c54d79139c77170.html> in a
   browser (or a private window) and confirm the file is publicly accessible.
   Return to Search Console and click **Verify**.
6. In the verified URL-prefix property, open **Sitemaps** and submit
   `https://menshikovs.github.io/termr/sitemap.xml`.
7. Use **URL inspection** for `https://menshikovs.github.io/termr/`, run a
   live test, and choose **Request indexing** if available.
8. Later, review **Pages** (indexing status) and **Performance** (search
   impressions, clicks, queries, and pages). Indexing and search visibility
   are not guaranteed, and updates can take time to appear.
