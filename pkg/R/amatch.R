#' Approximate string matching
#'
#' Approximate string matching equivalents of \code{R}'s native \code{\link[base]{match}} and \code{\%in\%}.
#'
#' \code{ain} is currently defined as 
#' 
#' \code{ain(x,table,...) <- function(x,table,...) amatch(x, table, nomatch=0,...) > 0}
#'
#'
#' @section Note on \code{NA} handling:
#' \code{R}'s native \code{\link[base]{match}} function matches \code{NA} with \code{NA}. This
#' may feel inconsistent with \code{R}'s usual \code{NA} handling, since for example \code{NA==NA} yields
#' \code{NA} rather than \code{TRUE}. In most cases, one may reason about the behaviour
#' under \code{NA} along the lines of ``if one of the arguments is \code{NA}, the result shall be \code{NA}'',
#' simply because not all information necessary to execute the function is available. One uses special 
#' functions such as \code{is.na}, \code{is.null} \emph{etc.} to handle special values. 
#'
#' The \code{amatch} function mimics the behaviour of \code{\link[base]{match}} by default: \code{NA} is 
#' matched with \code{NA} and with nothing else. Note that this is inconsistent with the behaviour of \code{\link{stringdist}}
#' since \code{stringdist} yields \code{NA} when at least one of the arguments is \code{NA}. The same inconsistency exists
#' between \code{\link[base]{match}} and \code{\link[utils]{adist}}. In \code{amatch} this behaviour
#' can be controlled by setting \code{matchNA=FALSE}. In that case, if any of the arguments in \code{x} 
#' is \code{NA}, the \code{nomatch} value is returned, regardless of whether \code{NA} is present in \code{table}.
#' In \code{\link[base]{match}} the behaviour can be controlled by setting the \code{incomparables} option.
#'
#' 
#' @param x elements to be approximately matched: will be coerced to \code{character}.
#' @param table lookup table for matching. Will be coerced to \code{character}.
#' @param nomatch The value to be returned when no match is found. This is coerced to integer. 
#' @param matchNA Should \code{NA}'s be matched? Default behaviour mimics the
#'   behaviour of base \code{\link[base]{match}}, meaning that \code{NA} matches
#'   \code{NA} (see also the note on \code{NA} handling below).
#' @param method Matching algorithm to use. See \code{\link{stringdist-metrics}}.
#' @param useBytes Perform byte-wise comparison. See \code{\link{stringdist-encoding}}.
#' @param weight For \code{method='osa'} or \code{'dl'}, the penalty for deletion, insertion, substitution and transposition, in that order.
#'   When \code{method='lv'}, the penalty for transposition is ignored. When \code{method='jw'}, the weights associated with characters
#'   of \code{a}, characters from \code{b} and the transposition weight, in that order.
#'   Weights must be positive and not exceed 1. \code{weight} is
#'   ignored completely when \code{method='hamming'}, \code{'qgram'}, \code{'cosine'}, \code{'Jaccard'}, \code{'lcs'}, or \code{soundex}. 
#' @param maxDist Elements in \code{x} will not be matched with elements of
#'  \code{table} if their distance is larger than \code{maxDist}. Note that the maximum distance between strings depends on the method:
#'  it should always be specified.
#' @param nthread Number of threads used by the underlying C-code. A sensible default is chosen,
#' see \code{\link{stringdist-parallelization}}.
#'   
#' @param q q-gram size, only when method is \code{'qgram'}, \code{'jaccard'}, or \code{'cosine'}.
#' @param p Winklers penalty parameter for Jaro-Winkler distance, with \eqn{0\leq p\leq0.25}. Only when method is \code{'jw'}
#'
#' @return \code{amatch} returns the position of the closest match of \code{x} in \code{table}. 
#'  When multiple matches with the same smallest distance metric exist, the first one is returned.
#'  \code{ain} returns a \code{logical} vector of length \code{length(x)} indicating wether 
#'  an element of \code{x} approximately matches an element in \code{table}.
#'
#' @example ../examples/amatch.R
#' @export
amatch <- function(x, table, nomatch=NA_integer_, matchNA=TRUE
  , method=c("osa","lv","dl","hamming","lcs","qgram","cosine","jaccard", "jw", "soundex") 
  , useBytes = FALSE
  , weight=c(d=1,i=1,s=1,t=1)
  , maxDist=0.1, q=1, p=0
  , nthread = getOption("sd_num_thread")){

  x <- as.character(x)
  table <- as.character(table)

  if (!useBytes){
    x <- enc2utf8(x)
    table <- enc2utf8(table)
  }

  method <- match.arg(method)
  stopifnot(
      all(is.finite(weight))
      , all(weight > 0)
      , all(weight <=1)
      , q >= 0
      , p <= 0.25
      , p >= 0
      , matchNA %in% c(TRUE,FALSE)
      , maxDist > 0
      , is.logical(useBytes)
      , ifelse(method %in% c('osa','dl'), length(weight) >= 4, TRUE)
      , ifelse(method %in% c('lv','jw') , length(weight) >= 3, TRUE)
      , nthread > 0
  )
  if (maxDist==Inf && !method %in% c('osa','lv','dl','hm','lcs') ) maxDist <- 0L;
  if (method == 'jw') weight <- weight[c(2,1,3)]
  switch(method,
    osa     = .Call('R_match_osa'       , x, table, as.integer(nomatch), as.integer(matchNA), as.double(weight), as.double(maxDist), useBytes, as.integer(nthread)),
    lv      = .Call('R_match_lv'        , x, table, as.integer(nomatch), as.integer(matchNA), as.double(weight), as.double(maxDist), useBytes, as.integer(nthread)),
    dl      = .Call('R_match_dl'        , x, table, as.integer(nomatch), as.integer(matchNA), as.double(weight), as.double(maxDist), useBytes, as.integer(nthread)),
    hamming = .Call('R_match_hm'        , x, table, as.integer(nomatch), as.integer(matchNA), as.integer(maxDist),useBytes,as.integer(nthread)),
    lcs     = .Call('R_match_lcs'       , x, table, as.integer(nomatch), as.integer(matchNA), as.integer(maxDist), useBytes, as.integer(nthread)),
    qgram   = .Call('R_match_qgram_tree', x, table, as.integer(nomatch), as.integer(matchNA), as.integer(q), as.double(maxDist), 0L, useBytes, as.integer(nthread)),
    cosine  = .Call('R_match_qgram_tree', x, table, as.integer(nomatch), as.integer(matchNA), as.integer(q), as.double(maxDist), 1L, useBytes, as.integer(nthread)),
    jaccard = .Call('R_match_qgram_tree', x, table, as.integer(nomatch), as.integer(matchNA), as.integer(q), as.double(maxDist), 2L, useBytes, as.integer(nthread)),
    jw      = .Call('R_match_jw'        , x, table, as.integer(nomatch), as.integer(matchNA), as.double(p), as.double(weight), as.double(maxDist), useBytes, as.integer(nthread)),
    soundex = .Call('R_match_soundex'   , x, table, as.integer(nomatch), as.integer(matchNA), useBytes, as.integer(nthread))
  )
}

#' @param ... parameters to pass to \code{amatch} (except \code{nomatch})
#'
#'
#' @rdname amatch
#' @export 
ain <- function(x,table,...){
  amatch(x, table, nomatch=0, ...) > 0
}

