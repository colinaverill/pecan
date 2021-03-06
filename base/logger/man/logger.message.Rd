% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/logger.R
\name{logger.message}
\alias{logger.message}
\title{Prints a message at a certain log level.}
\usage{
logger.message(level, msg, ...)
}
\arguments{
\item{level}{the level of the message (DEBUG, INFO, WARN, ERROR)}

\item{msg}{the message that should be printed.}

\item{...}{any additional text that should be printed.}
}
\description{
This function will print a message. This is the function that is responsible for
the actual printing of the message.
}
\details{
This is a place holder and will be later filled in with a more complex logging set
}
\examples{
\dontrun{
logger.message('DEBUG', 'variable', 5)
}
}
\author{
Rob Kooper
}
