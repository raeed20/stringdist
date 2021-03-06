
RECYCLEWARNING <- NULL


.onLoad <- function(libname, pkgname){
  RECYCLEWARNING <<- gettext(tryCatch( (1:2)+(1:3),warning=function(w) w$message ))

  nthread = parallel::detectCores()

  omp_thread_limit = as.numeric(Sys.getenv("OMP_THREAD_LIMIT"))
  if ( is.na(omp_thread_limit) ) omp_thread_limit <- nthread
  
  nthread = min(omp_thread_limit,nthread)
  if (nthread >= 4) nthread <- nthread - 1
 
  options(sd_num_thread=nthread)
}


#' Detect the presence of non-printable or non-ascii characters
#' 
#' @param x a \code{character} vector
#'
#' @details
#' Printable ASCII characters consist of space, \code{A-Z}, \code{a-z}, \code{0-9} and the characters
#'
#' \code{! "" # $ \% & ' ( ) * + , . / : ; < = > ? @@ [ ] \\ ^ _ ` { | } ~ -} 
#'
#' Note that this excludes tab (as it is a control character).
#'
#' 
#' @example ../examples/printable_ascii.R
#'
#'
#' @return A \code{logical} indicating which elements consist solely of printable ASCII characters.
#' @export 
printable_ascii <- function(x){ 
  # To portably detect ASCII characters, we need to specify them literally. Hence this monster of a character class. See ?regexp.

  # notes:
  # - caret (^) at the beginning negates what comes after, the caret in the middle is the actual character.
  # - the closing square bracket ] needs to be specified first
  # - double quote " and backslash are escaped
  # - the dash "-" is specified at the end since it would indicate a range otherwise
  # - see ? regexp.
  charclass <- paste0("[^]"
    , "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    , "0123456789"
    , " !\"#$%&'()*+,./:;<=>?@[\\^_`{|}~-"
    , "]"
  )  
  !grepl(charclass,x)
}



