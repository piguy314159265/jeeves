% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autoRun.R
\name{autoRun}
\alias{autoRun}
\title{Auto run tests on a new build of designer.}
\usage{
autoRun(plugins, downloadInstallers = FALSE, downloadDir,
  installAlteryx = FALSE, ...)
}
\arguments{
\item{plugins}{names of plugins to test.}

\item{downloadInstallers}{boolean indicating if installers should be downloaded.}

\item{downloadDir}{directory to which installers should be downloaded to}

\item{installAlteryx}{boolean indicating if Alteryx should be installed.}

\item{...}{additional arguments to pass to \code{\link{downloadInstallers}}}
}
\description{
This function runs all samples and tests for plugins.
}
\details{
\itemize{
  \item Dont leave Alteryx open when you run this function.
  \item Make sure you run it from a version of R not installed with Alteryx.
}
}
\examples{
# Run tests on OSR
\dontrun{
autoRun(
  plugins, downloadDir = downloadDir, 
  downloadInstallers = TRUE, installAlteryx = TRUE,
  rInstaller = 'RInstaller'
)
# Run tests on MRC
  downloadDir <- "."
  autoRun(
    plugins, downloadDir = downloadDir, downloadInstallers = TRUE, 
    installAlteryx = FALSE, rInstaller = 'RREInstaller'
  )
}
}

