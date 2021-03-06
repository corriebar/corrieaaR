% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/convert_ipynb_to_blogdown.R
\name{add_reticulate}
\alias{add_reticulate}
\title{Add a reticulate Cell}
\usage{
add_reticulate(
  md_text,
  python_path = reticulate::py_config()$python,
  chunk_options = ""
)
}
\arguments{
\item{md_text}{Markdown text as character string to which to attach the reticulate cell}

\item{python_path}{python path as string for reticulate. Defaults to the one detected by \code{\link[reticulate:py_config]{reticulate::py_config()}}}

\item{chunk_options}{string. Passes options to \code{\link[knitr:opts_chunk]{knitr::opts_chunk$set()}}}
}
\description{
This function adds a cell calling the reticulate library
to the beginning of the markdown text.
}
