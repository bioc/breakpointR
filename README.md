<img src="https://github.com/daewoooo/BreakPointR/raw/master/breakPointR_logo.png" />
=========================================================================

#BreakPointR
R Package for breakpoint detection in single cell Strand-seq data.

Collaborators: Ashley D Sanders, David Porubsky, Aaron Taudt

#Installation

### Bioconductor version (not available yet)
Under the development.

### Development version from Github
To install the development version from Github, follow the steps given below. The installation has only been tested on Ubuntu so far, if you need to install on Windows or Mac additional steps might be necessary (e.g. installation of Rtools from https://cran.r-project.org/bin/windows/Rtools/)

1. Install a recent version of R (>=3.2.0) from https://www.r-project.org/
2. Optional: For ease of use, install Rstudio from https://www.rstudio.com/
3. Open R and install all dependencies. Please ensure that you have writing permissions to install packages. Execute the following lines one by one:

   	install.packages("devtools")
	source("http://bioconductor.org/biocLite.R")
	biocLite("GenomicRanges")
	biocLite("GenomicAlignments")
	library(devtools)
	install_github("daewoooo/BreakPointR")
	# Or alternatively if the above line doesn't work:
	install_git("git://github.com/daewoooo/BreakPointR.git", branch = "master")

#How to use BreakPointR

Not available yet.

#Report Errors

If you encounter errors of any kind, please report an [issue here](https://github.com/daewoooo/BreakPointR/issues/new).
