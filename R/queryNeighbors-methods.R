#' Query all neighbors
#'
#' Find all neighbors in one data set that are in range of each point in another query data set.
#' 
#' @inheritParams findNeighbors-methods
#' @param query A numeric query matrix where rows are points and columns are dimensions.
#' @param ... Further arguments to pass to specific methods.
#' This is guaranteed to include \code{subset}, \code{get.index}, \code{get.distance} \code{BPPARAM} and \code{raw.index}.
#' See \code{?"\link{queryNeighbors-functions}"} for more details.
#' 
#' @return
#' A list is returned containing \code{index}, a list of integer vectors specifying the identities of the neighbors of each point;
#' and \code{distance}, a list of numeric vectors containing the distances to those neighbors.
#' See \code{?"\link{queryNeighbors-functions}"} for more details.
#' 
#' @details
#' The class of \code{BNINDEX} and \code{BNPARAM} will determine dispatch to specific methods.
#' Only one of these arguments needs to be defined to resolve dispatch.
#' However, if both are defined, they cannot specify different algorithms.
#' 
#' If \code{BNINDEX} is supplied, \code{X} does not need to be specified.
#' In fact, any value of \code{X} will be ignored as all necessary information for the search is already present in \code{BNINDEX}.
#' Similarly, any parameters in \code{BNPARAM} will be ignored.
#' 
#' If both \code{BNINDEX} and \code{BNPARAM} are missing, the function will default to the KMKNN algorithm by setting \code{BNPARAM=KmknnParam()}.
#' 
#' @author
#' Aaron Lun
#' 
#' @seealso
#' \code{\link{rangeQueryKmknn}} and  
#' \code{\link{rangeQueryVptree}} for specific methods.
#' 
#' @examples
#' Y <- matrix(rnorm(100000), ncol=20)
#' Z <- matrix(rnorm(10000), ncol=20)
#' k.out <- queryNeighbors(Y, Z, threshold=3)
#' v.out <- queryNeighbors(Y, Z, threshold=3, BNPARAM=VptreeParam())
#' 
#' k.dex <- buildKmknn(Y)
#' k.out2 <- queryNeighbors(Y,Z,  threshold=3, BNINDEX=k.dex)
#' k.out3 <- queryNeighbors(Y,Z,  threshold=3, BNINDEX=k.dex, BNPARAM=KmknnParam())
#' 
#' v.dex <- buildVptree(Y)
#' v.out2 <- queryNeighbors(Y,Z,  threshold=3, BNINDEX=v.dex)
#' v.out3 <- queryNeighbors(Y,Z,  threshold=3, BNINDEX=v.dex, BNPARAM=VptreeParam())
#' 
#' @aliases
#' queryNeighbors,missing,missing-method
#' 
#' queryNeighbors,missing,KmknnParam-method
#' queryNeighbors,KmknnIndex,missing-method
#' queryNeighbors,KmknnIndex,KmknnParam-method
#' 
#' queryNeighbors,missing,VptreeParam-method
#' queryNeighbors,VptreeIndex,missing-method
#' queryNeighbors,VptreeIndex,VptreeParam-method
#'
#' @name queryNeighbors-methods
#' @docType methods
NULL

##############
# S4 Factory #
##############

#' @importFrom BiocParallel SerialParam
.QUERYNEIGHBORS_GENERATOR <- function(FUN, ARGS=spill_args) {
    function(X, query, threshold, ..., BNINDEX, BNPARAM) {
        do.call(FUN, c(list(X=X, query=query, threshold=threshold, ...), ARGS(BNPARAM)))
    }
}

#' @importFrom BiocParallel SerialParam
.QUERYNEIGHBORS_GENERATOR_NOX <- function(FUN) {
    function(X, query, threshold, ..., BNINDEX, BNPARAM) {
        FUN(query=query, threshold=threshold, ..., precomputed=BNINDEX)
    }
}

####################
# Default dispatch #
####################

#' @export
setMethod("queryNeighbors", c("missing", "missing"), .QUERYNEIGHBORS_GENERATOR(queryNeighbors, .default_param))

####################
# Specific methods #
####################

#' @export
setMethod("queryNeighbors", c("missing", "KmknnParam"), .QUERYNEIGHBORS_GENERATOR(rangeQueryKmknn))

#' @export
setMethod("queryNeighbors", c("KmknnIndex", "missing"), .QUERYNEIGHBORS_GENERATOR_NOX(rangeQueryKmknn))

#' @export
setMethod("queryNeighbors", c("KmknnIndex", "KmknnParam"), .QUERYNEIGHBORS_GENERATOR_NOX(rangeQueryKmknn))

#' @export
setMethod("queryNeighbors", c("missing", "VptreeParam"), .QUERYNEIGHBORS_GENERATOR(rangeQueryVptree))

#' @export
setMethod("queryNeighbors", c("VptreeIndex", "missing"), .QUERYNEIGHBORS_GENERATOR_NOX(rangeQueryVptree))

#' @export
setMethod("queryNeighbors", c("VptreeIndex", "VptreeParam"), .QUERYNEIGHBORS_GENERATOR_NOX(rangeQueryVptree))
