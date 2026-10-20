# Build with the same pkgdown entry point as GitHub Pages, then add page URLs.
# jsonlite and xml2 are existing pkgdown tooling dependencies.
config <- yaml::read_yaml("_pkgdown.yml")
description <- read.dcf("DESCRIPTION")[1, ]
base_url <- paste0(sub("/+$", "", config$url), "/")
site <- config$destination
summary <- sub("\\..*$", ".", gsub("[[:space:]]+", " ", description[["Description"]]))
people <- eval(parse(text = description[["Authors@R"]]),
               envir = list(person = utils::person), enclos = baseenv())
authors <- Filter(function(person) "aut" %in% person$role, as.list(people))
stopifnot(length(authors) > 0L,
          identical(description[["License"]], "MIT + file LICENSE"),
          file.exists("LICENSE"))
software <- list(
  "@context" = "https://schema.org",
  "@type" = "SoftwareSourceCode",
  name = description[["Package"]],
  description = summary,
  url = base_url,
  codeRepository = "https://github.com/menshikovs/termr",
  programmingLanguage = "R",
  runtimePlatform = "R",
  license = "https://opensource.org/license/mit/",
  version = description[["Version"]],
  author = lapply(authors, function(person) {
    list("@type" = "Person", name = paste(c(person$given, person$family), collapse = " "))
  })
)
pkgdown::build_site_github_pages(
  dest_dir = site, new_process = FALSE, install = FALSE,
  override = list(template = list(params = list(
    social_description = summary,
    software_jsonld = as.character(jsonlite::toJSON(software, auto_unbox = TRUE, pretty = TRUE))
  )))
)

# pkgdown 2.2.1 does not expose the output path to its header templates.
# Use its native sitemap to supply page-specific absolute URLs after rendering.
# Do not change native Open Graph fields, redirects, or verification assets.
sitemap <- xml2::read_xml(file.path(site, "sitemap.xml"))
urls <- xml2::xml_text(xml2::xml_find_all(sitemap, "//*[local-name()='loc']"))
stopifnot(length(urls) > 0L, all(startsWith(urls, base_url)))
for (url in urls) {
  relative <- substring(url, nchar(base_url) + 1L)
  path <- file.path(site, relative)
  html <- xml2::read_html(path, encoding = "UTF-8")
  head <- xml2::xml_find_first(html, "//head")
  if (!length(xml2::xml_find_all(head, "meta[@property='og:title']"))) next
  canonical <- if (relative == "index.html") base_url else url
  fields <- list(
    list(xpath = "link[@rel='canonical']", element = "link", key = "rel", value = "canonical", attribute = "href"),
    list(xpath = "meta[@property='og:url']", element = "meta", key = "property", value = "og:url", attribute = "content")
  )
  for (field in fields) {
    existing <- xml2::xml_find_all(head, field$xpath)
    if (length(existing)) {
      stopifnot(length(existing) == 1L,
                identical(xml2::xml_attr(existing, field$attribute), canonical))
    } else {
      attributes <- setNames(list(field$value, canonical), c(field$key, field$attribute))
      do.call(xml2::xml_add_child, c(list(head, field$element), attributes))
    }
  }
  xml2::write_html(html, path, options = character())
}
cat("Added canonical and Open Graph URLs to pkgdown content pages.\n")
