
# corrieaaR

<!-- badges: start -->
<!-- badges: end -->

A collection of function I frequently use. Use with care.

## Installation

You can install the latest version of corrieaaR from Github with:

``` r
devtools::install_github("corriebar/corrieaaR")
```

## Requirements

You'll need [`nbconvert`](https://nbconvert.readthedocs.io/en/latest/) and [`nbstripout`](https://github.com/kynan/nbstripout) which you can install as follows:
```
pip install nbconvert nbstripout
```

## Convert jupyter notebook to Rmd

I build this package to be able to convert jupyter notebooks with Python code to an .Rmd file, in particular to then be used for a blogdown blog post.
In your blogdown project, execute the following:
``` r
library(corrieaar)
notebook_file <- "path/to/awesome_notebook.ipynb"
new_post_from_ipynb(notebook_file)
```
This creates an .Rmd file in the `content/post` folder. Blogdown will then render the notebook first (that is, execute it) when you run `serve_site()`
```r
blogdown::serve_site()
```
You can pass global chunk options and specify the Python version which `reticulate` should use:
```r
new_post_from_ipynb(notebook_file, 
                    chunk_options = "echo=FALSE",
                    python_path = "path/to/your/bin/python")
```        

To only convert to an .Rmd use the following:
```r
Rmd_from_ipynb(notebook_file)
```
