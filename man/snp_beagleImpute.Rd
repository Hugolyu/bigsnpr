% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/external-software.R
\name{snp_beagleImpute}
\alias{snp_beagleImpute}
\title{Imputation}
\usage{
snp_beagleImpute(beagle.path, plink.path, bedfile.in, bedfile.out = NULL,
  memory.max = 3, ncores = 1, extra.options = "")
}
\arguments{
\item{beagle.path}{Path to the executable of Beagle v4+.}

\item{plink.path}{Path to the executable of PLINK 1.9.}

\item{bedfile.in}{Path to the input bedfile.}

\item{bedfile.out}{Path to the output bedfile. Default is created by
appending \code{"_impute"} to \code{prefix.in} (\code{bedfile.in} without extension).}

\item{memory.max}{Max memory (in Gb) to be used. It is internally rounded
to be an integer. Default is \code{3}.}

\item{ncores}{Number of cores to be used. Default is \code{1}. An usually good
value for this parameter is \code{ncores = parallel::detectCores() - 1}.}

\item{extra.options}{Other options to be passed to Beagle as a string. More
options can be found at Beagle's website.}
}
\value{
The path of the new bedfile.
}
\description{
Imputation using \strong{Beagle} version 4.
}
\details{
Downloads and more informations can be found at the following websites
\itemize{
\item \href{https://www.cog-genomics.org/plink2}{PLINK},
\item \href{https://faculty.washington.edu/browning/beagle/beagle.html}{Beagle}.
}
}
\references{
B L Browning and S R Browning (2016).
Genotype imputation with millions of reference samples.
Am J Hum Genet 98:116-126.
\url{dx.doi.org/doi:10.1016/j.ajhg.2015.11.020}
}