% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fit_ld.R
\name{fit_ld}
\alias{fit_ld}
\title{Bayesian inference for mixed models}
\usage{
fit_ld(fixed, random, data, id, model, spline, priors = list(), ...)
}
\arguments{
\item{fixed}{A two-sided formula for fixed effects}

\item{random}{A one-sided formula for random effects}

\item{data}{A data frame to extract the fixed and random effects design matrices}

\item{id}{A character string that indicates the column name for the id column}

\item{model}{A character string for model identification; options are: 
"nor_nor", "t_t_mod1", "t_t_mod2", "t_t_mod3", "nor_t_mod3", "t_t_tv", "nor_t_tv"}

\item{spline}{A list with two elements; first element is the name of the time variable, 
and number of knots}

\item{priors}{A list of hyperparameters; theta, Omega, sigma_B, sigma_Z, beta (for tv). See details below.}

\item{...}{to be passed to the \code{stan} function}
}
\value{
Returns the output of the \code{stan} function
}
\description{
Fits mixed models with Normal and non-Normal distributions
}
\details{
This is a wrapper function for fitting mixed effects models. 
         Cauchy distribution is assumed as the prior for theta (QR decomposed alpha), 
         half-Cauchy for sigma_B (standard deviations of var-cov of B), 
         half-Cauchy for sigma_Z (standard deviation of error),
         Cauchy for beta (time-varying degree of freedom parameters)
}
\examples{
For examples, see the repository at https://github.com/ozgurasarstat/robjm-run                                              
}
