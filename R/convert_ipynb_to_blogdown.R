#' Transform Python Markdown Code Snippets
#'
#' This function takes a markdown-text as string-input and transforms
#' each python code snippet in an executable python cell for Rmarkdown
#' @param md_text markdown text as string
transform_python_cells <- function(md_text) {
  stringr::str_replace_all(md_text, "```python", "```{python}" )
}

#' Add a YAML header
#'
#' Adds a YAML header to your markdown text
#' @param md_text markdown text as string
#' @param title title of the markdown as string. Defaults to ""
#' @param author author as string. Defaults to ""
#' @param date day of creation as string. Defaults to \code{Sys.Date()}
add_yaml <- function(md_text, title="", author="", date=Sys.Date()) {
    yaml_header <- glue::glue("---
    title: '{title}'
    author: '{author}'
    date: '{date}'
    output: html_document
    ---")
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
#' @param md_text Markdown text as character string to which to attach the reticulate cell
#' @param python_path python path as string for reticulate. Defaults to the one detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}
#' @param chunk_options string. Passes options to \code{\link[knitr:opts_chunk]{knitr::opts_chunk$set()}}
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
#' Rmd file with a reticulate chunk. Returns the Rmd string without YAML header
#' @param md_file path to the markdown file
#' @param chunk_options string. Passes options to \code{\link[knitr:opts_chunk]{knitr::opts_chunk$set()}}. Defaults to ""
#' @param python_path python path as string for reticulate. Defaults to the one detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}
md_to_Rmd_text <- function(md_file,
                           chunk_options = "",
                           python_path = reticulate::py_config()$python) {
  md_text <- readr::read_file(md_file)

  md_text <- transform_python_cells(md_text)
  add_reticulate(md_text, python_path, chunk_options = chunk_options)
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
  system(glue::glue("cat '{ipynb_file}' | nbstripout > '{temp_file}'"))
  system2("jupyter", args = c("nbconvert",
                              glue::glue("--output '{output_filename}'"),
                              glue::glue("--to markdown '{temp_file}'"), "--ClearMetadataPreprocessor.enabled=True", "--ClearOutput.enabled=True"))
  system2("rm", args = c(glue::glue("'{temp_file}'")) )
  stringr::str_replace(ipynb_file, ".ipynb", ".md")
}

#' Convert Jupyter Notebook to Rmd
#'
#' Converts a jupyter notebook to Rmd style md. Returns the string without YAML header.
#' @param ipynb_file path to the jupyter notebook
#' @param chunk_options string. Passes options to \code{\link[knitr:opts_chunk]{knitr::opts_chunk$set()}}. Defaults to ""
#' @param python_path python path as string for reticulate. Defaults to the
#' one detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}
ipynb_to_Rmd_text <- function(ipynb_file,
                              chunk_options = "",
                              python_path = reticulate::py_config()$python) {
  md_file <- ipynb_to_md(ipynb_file)
  md_to_Rmd_text(md_file, chunk_options, python_path)
}

#' Creates a new Blogdown Post from a Jupyter Notebook
#'
#' Creates a new blogdown post and appends the jupyter
#' notebook content as Rmd-style text. The notebook
#' gets transformed into a runnable Rmd with python chunks.
#' @param ipynb_file path to the jupyter notebook
#' @param chunk_options global chunk options as charachter vector. Passes options to \code{\link[knitr:opts_chunk]{knitr::opts_chunk$set()}}. Defaults to ""
#' @param python_path python path as string for reticulate. Defaults to the one detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}
#' @param title title of the markdown. Defaults to the name of the notebook
#' @param kind content type to create
#' @param open whether to open the generated file after creation
#' @param author author.
#' @param categories character vector of category names
#' @param tags character vector of tag names
#' @param date date of the post. Defaults to \code{Sys.Date()}
#' @param file filename of the post. Will be automatically generated by default from the title
#' @param slug slug of the post. Also automatically generated by default from the title
#' @param title_case function to convert the title to title case
#' @param subdir if specified the post will be generated in a subdirectoy of 'content/'
#' @param ext extension of the generated file. Defaults to .Rmd
#' @return Returns the file name of the newly generated file.
#' @seealso \code{\link[blogdown:new_post]{blogdown::new_post()}} for which this function is a wrapper.
#' @export
new_post_from_ipynb <- function(ipynb_file, chunk_options = "", python_path = reticulate::py_config()$python,
                                title="", kind = "", open = interactive(), author = getOption("blogdown.author"),
                                categories = NULL, tags = NULL, date = Sys.Date(), file = NULL,
                                slug = NULL, title_case = getOption("blogdown.title_case"),
                                subdir = getOption("blogdown.subdir", "post"), ext = getOption("blogdown.ext",
                                                                                               ".Rmd")) {
  if (title == "")  title <- stringr::str_replace( basename( ipynb_file), ".ipynb", "")

  new_post_file <- blogdown::new_post(title, kind = kind, open = FALSE, author = author,
                     categories = categories, tags = tags, date = date, file = file,
                     slug = slug, title_case = title_case,
                     subdir = subdir, ext = ext )
  generated_rmd <- ipynb_to_Rmd_text(ipynb_file, chunk_options, python_path )

  write(generated_rmd, file=new_post_file, append = TRUE)

  if (open)
    open_file(new_post_file)
  new_post_file

}

open_file <- function(x) {
  tryCatch(rstudioapi::navigateToFile(x), error = function(e) utils::file.edit(x))
}

#' Creates an Rmd file from a Jupyter Notebook
#'
#' @param ipynb_file path to the jupyter notebook
#' @param chunk_options global chunk options as charachter vector. Passes options to kitr::opts_chunk$set(). Defaults to ""
#' @param python_path python path as string for reticulate. Defaults to the one
#' detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}
#' @param open whether to open the generated file after creation
#' @param title title of the markdown as string. Defaults to ""
#' @param author author as string. Defaults to ""
#' @param date day of creation as string. Defaults to \code{Sys.Date()}
#' @export
Rmd_from_ipynb <- function(ipynb_file, chunk_options = "", python_path = reticulate::py_config()$python,
                           open = interactive(), title = "", author = "", date = Sys.Date()) {
  generated_rmd <- ipynb_to_Rmd_text(ipynb_file, chunk_options, python_path)

  output_filename <- stringr::str_replace(ipynb_file, ".ipynb", ".Rmd")

  rmd_text <- add_yaml(generated_rmd, title, author, date)
  write(rmd_text, file=output_filename)

  if (open)
    open_file(output_filename)
  output_filename

}
