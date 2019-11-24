#' Transform Python Markdown Code Snippets
#'
#' This function takes a markdown-text as string-input and transforms
#' each python code snippet in an executable python cell for Rmarkdown
#' @param md_text markdown text as string
transform_python_cells <- function(md_text) {
  stringr::str_replace_all(md_text, "```python", "```{{python }}" )
}

#' Make a Slug out of a Title
#'
#' This function parses a title into a slug
#' @param title title as string
#' @examples make_slub("This is a nice title")
#' @importFrom magrittr "%>%"
make_slug <- function(title) {
  stringr::str_replace_all(title, "[[:punct:]]", "") %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("[[:space:]]", "-")
}

#' Add a YAML header
#'
#' Adds a YAML header to your markdown
#' @param md_text markdown text as string
#' @param title title of the markdown as string. Defaults to ""
#' @param author author as string. Defaults to ""
#' @param date day of creation as string. Defaults to \code{\link{today()}}
#' @param blogdown logical indicating if a blogdown header should be generated. Otherwise a normal .Rmd header is generated. Defaults to FALSE
add_yaml <- function(md_text, title="", author="", date=lubridate::today(), blogdown=FALSE) {
  if (blogdown) {
    slug <- make_slug(title)
    yaml_header <- glue::glue("---
    title: '{title}'
    author: {author}
    date: '{date}'
    slug: {slug}
    categories: []
    tags: []
    comments: yes
    image: images/tea_with_books.jpg
    menu: ''
    share: yes
    ---

    ")
  }
  else {
    yaml_header <- glue::glue("---
    title: '{title}'
    author: '{author}'
    date: '{date}'
    output: html_document
    ---")
  }
  glue::glue("{yaml_header}\n{md_text}")
}

#' Removes Plot Outputs
#'
#' This function removes any png plot outputs.
#' @param md_text markdown text as string
remove_pngs <- function(md_text) {
  stringr::str_replace_all(md_text, "!\\[png\\]\\(.*?\\)", "")
}

#' Add a reticulate Cell
#'
#' This function adds a cell calling the reticulate library
#' to the beginning of the markdown text.
#' @param python_path python path as string for reticulate. Defaults to the one detected by \code{\link{reticulate::py_config()}}
#' @param chunk_options string. Passes options to kitr::opts_chunk$set()
add_reticulate <- function(md_text, python_path = reticulate::py_config()$python, chunk_options="") {
  reticulate_cell <- glue::glue("```{{r, include=FALSE}}
  knitr::opts_chunk$set({chunk_options})
  library(reticulate)
  use_python('{python_path}', required = T)
  ```")

  glue::glue("{reticulate_cell}\n{md_text}",)
}

#' Convert a md to rmd
#'
#' Converts a markdown file containing python code chunks to a
#' Rmd file using reticulate
#' @param md_file path to the markdown file
#' @param output_file path to the generated Rmd-file. Defaults to the same name as the input file
#' @param chunk_options string. Passes options to kitr::opts_chunk$set(). Defaults to ""
#' @param title title of the markdown. Defaults to ""
#' @param author author. Defaults to ""
#' @param date day of creation as string. Defaults to \code{\link{lubridate::today()}}
#' @param blogdown logical indicating if a blogdown header should be generated. Otherwise a normal .Rmd header is generated. Defaults to FALSE
#' @param python_path python path as string for reticulate. Defaults to the one detected by \code{\link{reticulate::py_config()}}
#' @importFrom magrittr "%>%"
md_to_Rmd <- function(md_file, output_file = "",
                      chunk_options="",
                      title = "",
                      author = "",
                      date=lubridate::today(),
                      blogdown = FALSE,
                      python_path = reticulate::py_config()$python) {
  md_text <- readr::read_file(md_file)
  if (output_file == "" ) {
    rmd_path <- stringr::str_replace(md_file, ".md", ".Rmd") }
  else {
    rmd_path <- output_file
  }

  transform_python_cells(md_text) %>%
    add_reticulate(python_path, chunk_options = chunk_options) %>%
    add_yaml(title = title, author = author, date = date, blogdown = blogdown ) %>%

  readr::write_file(path=rmd_path)
}

#' Jupyter Notebook to markdown
#'
#' Uses nbconvert and nbstripout to convert the jupyter notebook to
#' a clean markdown.
#' @param ipynb_file path to the jupyter notebook
ipynb_to_md <- function(ipynb_file) {
  dir_name <- dirname(ipynb_file)
  file_name <- basename(ipynb_file)
  output_filename <- stringr::str_replace(file_name, ".ipynb", "")
  temp_file <- file.path(dir_name, glue::glue("temp_{file_name}") )
  system(glue::glue("cat '{ipynb_file}' | nbstripout > '{temp_file}'") )
  system2("jupyter", args = c("nbconvert",
                              glue::glue("--output '{output_filename}'"),
                              glue::glue("--to markdown '{temp_file}'"), "--ClearMetadataPreprocessor.enabled=True", "--ClearOutput.enabled=True"))
  system2("rm", args = c(glue::glue("'{temp_file}'")) )
  stringr::str_replace(ipynb_file, ".ipynb", ".md")
}

#' Convert Jupyter Notebook to Rmd
#'
#' Converts a jupyter notebook to rmd.
#' @param ipynb_file path to the jupyter notebook
#' @param output_file path to the generated Rmd-file. Defaults to the same name as the input file
#' @param blogdown logical indicating if a blogdown header should be generated. Otherwise a normal .Rmd header is generated.
#' @param ... arguments to be passed to \code{\link{md_to_Rmd}} such as title, author, or date
#' @export
ipynb_to_Rmd <- function(ipynb_file, output_file = "", blogdown, ...) {
  md_file <- ipynb_to_md(ipynb_file)
  md_to_Rmd(md_file, output_file = output_file, blogdown = blogdown, ...)
}

#' Convert Jupyter Notebook to Blogdown Post
#'
#' Converts a jupyter notebook to a Blogdown post.
#' @param ipynb_file path to the jupyter notebook
#' @param chunk_options string. Passes options to kitr::opts_chunk$set(). Defaults to ""
#' @param title title of the markdown. Defaults to ""
#' @param author author. Defaults to ""
#' @param date day of creation as string. Defaults to \code{\link{lubridate::today()}}
#' @param ... arguments passed to \code{\link{md_to_Rmd}} such as the python path used for reticulate
#' @export
ipynb_to_blogdown_post <- function(ipynb_file,
                                   chunk_options = "",
                                   title = "",
                                   author = "",
                                   date=lubridate::today(),
                                   ...){
  if (title == "") title <- stringr::str_replace( basename( ipynb_file), ".ipynb", "")
  slug <- make_slug(title)
  file_name <- glue::glue("{date}-{slug}.Rmd")
  output_file <- here::here("content", "post", file_name)
  ipynb_to_Rmd(ipynb_file, output_file = output_file,
               title=title, author=author, date=date,
               chunk_options = chunk_options, blogdown = TRUE,
               ... )
}

