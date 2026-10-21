# Run after a local pkgdown build: Rscript tools/validate-site-seo.R
# Uses website tooling already installed with pkgdown, not runtime dependencies.
site <- "site"
base_url <- "https://menshikovs.github.io/termr/"
token <- "y-1CU_OpfbxmAGDGQm3qi8Xc9RcalnzCOzJ3CZ2VA_o"
bing_token <- "ED124DAA8CF210E4D6CB70008D1A15B1"
bing_tag <- sprintf('<meta name="msvalidate.01" content="%s" />', bing_token)
config <- yaml::read_yaml("_pkgdown.yml")
description <- read.dcf("DESCRIPTION")
stopifnot(
  identical(config$url, base_url),
  identical(config$destination, site),
  identical(config$template$params$google_site_verification, token),
  grepl(bing_tag, config$template$includes$in_header, fixed = TRUE),
  identical(unname(description[1, "Title"]), "Reactive Terminal UI Framework for R"),
  identical(unname(description[1, "BugReports"]), "https://github.com/menshikovs/termr/issues")
)

# Execute the homepage quick start with a headless driver instead of run().
lines <- readLines("pkgdown/index.md", encoding = "UTF-8", warn = FALSE)
start <- grep("^```r$", lines)[[1]]
end <- which(seq_along(lines) > start & lines == "```")[[1]]
expressions <- parse(text = lines[seq.int(start + 1L, end - 1L)])
stopifnot(identical(expressions[[length(expressions)]], quote(run(application))))
env <- new.env(parent = globalenv())
eval(expressions[-length(expressions)], envir = env)
verify_home_app <- function() {
  pilot <- termr::test_app(env$application, width = 40, height = 8)
  on.exit(pilot$stop(), add = TRUE)
  stopifnot(any(grepl("Hello from termr", pilot$screen_text(), fixed = TRUE)))
  pilot$press("enter")
  stopifnot(pilot$exited)
}
verify_home_app()
cat("PASS homepage application renders and Quit button exits headlessly\n")

pages <- c("index.html", "articles/getting-started.html",
           "articles/terminal-dashboards.html", "articles/testing-terminal-ui.html",
           "reference/app.html", "reference/data_table.html", "reference/test_app.html",
           "CONTRIBUTING.html", "SECURITY.html", "COMMUNITY_SETUP.html",
           "ARCHITECTURE.html", "README.zh-CN.html", "CODE_OF_CONDUCT.html")
titles <- character()
for (page in pages) {
  path <- file.path(site, page)
  html <- xml2::read_html(path)
  title <- xml2::xml_text(xml2::xml_find_all(html, "//head/title"))
  desc <- xml2::xml_find_all(html, "//head/meta[@name='description']")
  verification <- xml2::xml_find_all(html, "//head/meta[@name='google-site-verification']")
  bing_verification <- xml2::xml_find_all(html, "//head/meta[@name='msvalidate.01']")
  robots <- xml2::xml_attr(xml2::xml_find_all(html, "//meta[@name='robots']"), "content")
  canonicals <- xml2::xml_attr(xml2::xml_find_all(html, "//link[@rel='canonical']"), "href")
  stopifnot(length(title) == 1L, nzchar(title), grepl("termr", title, fixed = TRUE),
            length(desc) == 1L, nzchar(xml2::xml_attr(desc, "content")),
            length(verification) == 1L,
            identical(xml2::xml_attr(verification, "content"), token),
            length(bing_verification) == 1L,
            identical(xml2::xml_attr(bing_verification, "content"), bing_token),
            !any(grepl("noindex|nofollow", robots, ignore.case = TRUE)),
            length(xml2::xml_find_all(html, "//main//h1")) == 1L,
            length(canonicals) == 1L)
  expected_url <- if (page == "index.html") base_url else paste0(base_url, page)
  if (length(canonicals)) stopifnot(identical(canonicals, expected_url))
  for (property in c("og:title", "og:description", "og:image")) {
    node <- xml2::xml_find_all(html, sprintf("//head/meta[@property='%s']", property))
    stopifnot(length(node) == 1L, nzchar(xml2::xml_attr(node, "content")))
  }
  image <- xml2::xml_attr(xml2::xml_find_all(html, "//meta[@property='og:image']"), "content")
  stopifnot(identical(image, paste0(base_url, "widget-showcase.png")),
            file.exists(file.path(site, "widget-showcase.png")))
  titles <- c(titles, title)

  # Check local navigation, article cross-links, assets, and fragment targets.
  links <- unique(c(xml2::xml_attr(xml2::xml_find_all(html, "//a[@href]"), "href"),
                    xml2::xml_attr(xml2::xml_find_all(html, "//img[@src]"), "src")))
  for (link in links) {
    if (grepl("^(https?:|mailto:|data:|//)", link)) next
    parts <- strsplit(link, "#", fixed = TRUE)[[1]]
    target <- if (!length(parts) || !nzchar(parts[[1]])) path else
      file.path(dirname(path), utils::URLdecode(sub("\\?.*$", "", parts[[1]])))
    if (!file.exists(target)) stop("Broken local link in ", page, ": ", link)
    if (length(parts) > 1L && nzchar(parts[[2]]) && grepl("\\.html$", target)) {
      ids <- xml2::xml_attr(xml2::xml_find_all(xml2::read_html(target), "//*[@id]"), "id")
      fragment <- utils::URLdecode(parts[[2]])
      Encoding(fragment) <- "UTF-8"
      if (!fragment %in% ids) stop("Missing fragment in ", page, ": ", link)
    }
  }
  cat("PASS metadata and local links:", page, "\n")
}
stopifnot(!anyDuplicated(titles))
home <- xml2::read_html(file.path(site, "index.html"))
stopifnot(
  identical(xml2::xml_text(xml2::xml_find_first(home, "//title")),
            paste(config$home$title, "\u2022", "termr")),
  identical(trimws(xml2::xml_attr(xml2::xml_find_first(home, "//meta[@name='description']"),
                                "content")), trimws(config$home$description))
)

sitemap <- xml2::read_xml(file.path(site, "sitemap.xml"))
urls <- xml2::xml_text(xml2::xml_find_all(sitemap, "//*[local-name()='loc']"))
stopifnot(length(urls) > 0L, !anyDuplicated(urls), all(startsWith(urls, base_url)))
paths <- substring(urls, nchar(base_url) + 1L)
stopifnot(all(file.exists(file.path(site, paths))), all(pages %in% paths))
cat("PASS sitemap:", length(urls), "unique HTTPS URLs with existing local pages\n")
cat("Native non-content entries:", paste(paths[grepl("404|google.*\\.html$", paths)], collapse = ", "), "\n")

# Check every content page, including indexes and pages with fallback descriptions.
people <- eval(parse(text = description[1, "Authors@R"]),
               envir = list(person = utils::person), enclos = baseenv())
authors <- Filter(function(person) "aut" %in% person$role, as.list(people))
author_names <- vapply(authors, function(person) paste(c(person$given, person$family), collapse = " "), character(1))
social_pages <- 0L
for (page in paths) {
  html <- xml2::read_html(file.path(site, page), encoding = "UTF-8")
  if (!length(xml2::xml_find_all(html, "//head/meta[@property='og:title']"))) next
  meta <- function(key, attribute = "property") {
    nodes <- xml2::xml_find_all(html, sprintf("//head/meta[@%s='%s']", attribute, key))
    stopifnot(length(nodes) == 1L, nzchar(xml2::xml_attr(nodes, "content")))
    xml2::xml_attr(nodes, "content")
  }
  expected_url <- if (page == "index.html") base_url else paste0(base_url, page)
  canonical <- xml2::xml_find_all(html, "//head/link[@rel='canonical']")
  stopifnot(length(canonical) == 1L,
            identical(xml2::xml_attr(canonical, "href"), expected_url),
            identical(meta("og:url"), expected_url),
            identical(meta("og:type"), "website"),
            identical(meta("og:site_name"), "termr"),
            identical(meta("og:locale"), "en_US"),
            identical(meta("twitter:card", "name"), "summary_large_image"),
            identical(meta("twitter:title", "name"), meta("og:title")),
            identical(meta("twitter:description", "name"), meta("og:description")),
            identical(meta("description", "name"), meta("og:description")),
            identical(meta("twitter:image", "name"), meta("og:image")),
            identical(xml2::xml_text(xml2::xml_find_first(html, "//head/title")),
                      paste(meta("og:title"), "\u2022", "termr")),
            grepl("termr", meta("keywords", "name"), fixed = TRUE))
  image <- meta("og:image")
  stopifnot(startsWith(image, base_url),
            file.exists(file.path(site, substring(image, nchar(base_url) + 1L))))
  scripts <- xml2::xml_find_all(html, "//head/script[@type='application/ld+json']")
  stopifnot(length(scripts) == 1L)
  json <- xml2::xml_text(scripts)
  stopifnot(jsonlite::validate(json))
  software <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  stopifnot(identical(software[["@context"]], "https://schema.org"),
            identical(software[["@type"]], "SoftwareSourceCode"),
            identical(software$name, unname(description[1, "Package"])),
            identical(software$version, unname(description[1, "Version"])),
            identical(software$url, base_url),
            identical(software$codeRepository, "https://github.com/menshikovs/termr"),
            identical(software$programmingLanguage, "R"),
            identical(software$runtimePlatform, "R"),
            identical(software$license, "https://opensource.org/license/mit/"),
            identical(unname(description[1, "License"]), "MIT + file LICENSE"),
            nzchar(software$description),
            startsWith(gsub("[[:space:]]+", " ", description[1, "Description"]), software$description),
            identical(vapply(software$author, `[[`, character(1), "name"), author_names))
  social_pages <- social_pages + 1L
}
cat("PASS JSON-LD, Open Graph, Twitter, keywords, canonical URLs, and image assets:", social_pages, "content pages\n")
redirects <- list.files(site, pattern = "\\.html$", full.names = TRUE, recursive = TRUE)
noindex <- vapply(redirects, function(path) {
  html <- xml2::read_html(path)
  any(grepl("noindex", xml2::xml_attr(xml2::xml_find_all(html, "//meta[@name='robots']"), "content")))
}, logical(1))
for (path in redirects[noindex]) {
  html <- xml2::read_html(path)
  canonical <- xml2::xml_attr(xml2::xml_find_all(html, "//link[@rel='canonical']"), "href")
  stopifnot(length(canonical) == 1L, startsWith(canonical, base_url),
            file.exists(file.path(site, substring(canonical, nchar(base_url) + 1L))),
            !substring(path, nchar(site) + 2L) %in% paths)
}
cat("PASS redirect canonical destinations and sitemap exclusion:", sum(noindex), "\n")

verification_file <- "google9c54d79139c77170.html"
stopifnot(identical(unname(tools::md5sum(file.path("pkgdown/assets", verification_file))),
                    unname(tools::md5sum(file.path(site, verification_file)))),
          identical(unname(tools::md5sum("pkgdown/assets/BingSiteAuth.xml")),
                    unname(tools::md5sum(file.path(site, "BingSiteAuth.xml")))),
          identical(unname(tools::md5sum("docs/images/widget-showcase.png")),
                    unname(tools::md5sum(file.path(site, "widget-showcase.png")))),
          file.exists(file.path(site, ".nojekyll")))
cat("PASS retained Google and Bing verification files, preview image, and Pages artifact marker\n")
cat("NOTE tools/build-site.R adds page URLs after pkgdown renders its native metadata.\n")
