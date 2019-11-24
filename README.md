
# corrieaaR

<!-- badges: start -->
<!-- badges: end -->

A collection of function I frequently use. Use with care.

## Installation

You can install the latest version of corrieaaR from Github with:

``` r
devtools::install_github("corriebar/corrieaar")
```

## Convert jupyter notebook to Rmd

I build this package to be able to convert jupyter notebooks with Python code to an .Rmd file, in particular to then be used for a blogdown blog post.
In your blogdown project, execute the following:
``` r
library(corrieaar)
notebook_file <- "path/to/awesome_notebook.ipynb"
ipynb_to_blogdown_post(notebook_file)
```
This creates an .Rmd file in the `content/post` folder. You'll still have to knitter the Rmarkdown file before serving it.
You can pass global chunk options and specify the Python version which `reticulate` should use:
```r
ipynb_to_blogdown_post(notebook_file, 
                        chunk_options = "echo=FALSE",
                        python_path = "path/to/your/bin/python")
```        

To only convert to an .Rmd use the following:
```r
ipynb_to_Rmd(notebook_file)
```
