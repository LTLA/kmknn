#' @importFrom BiocParallel SerialParam bpmapply
.template_query_knn <- function(X, query, k, get.index=TRUE, get.distance=TRUE, 
    last=k, BPPARAM=SerialParam(), precomputed=NULL, transposed=FALSE, subset=NULL, 
    exact=TRUE, raw.index=FALSE, warn.ties=TRUE,
    buildFUN, searchFUN, searchArgsFUN, distance="Euclidean", ...)
# Identifies nearest neighbours in 'X' from a query set.
#
# written by Aaron Lun
# created 19 June 2018
{
    if (exact) {
        precomputed <- .setup_precluster(X, precomputed, raw.index, buildFUN=buildFUN, distance=distance, ...)
        common.args <- list(X=bndata(precomputed), warn_ties=warn.ties)
    } else {
        if (is.null(precomputed)) {
            precomputed <- buildFUN(X, distance=distance, ...)
            on.exit(unlink(precomputed[['path']]))
        }
        common.args <- list()
    }

    k <- .refine_k(k, precomputed, query=TRUE)
    last <- min(last, k)

    q.out <- .setup_query(query, transposed, subset, distance=distance)
    query <- q.out$query        
    job.id <- q.out$index
    reorder <- q.out$reorder

    # Dividing jobs up for NN finding (subsetting here
    # to avoid serializing the entire matrix to all workers).
    Q <- .split_matrix_for_workers(query, job.id, BPPARAM)
    common.args <- c(searchArgsFUN(precomputed), common.args,
        list(dtype=bndistance(precomputed), nn=k, last=last))

    collected <- bpmapply(FUN=searchFUN, query=Q,
        MoreArgs=c(common.args, list(get_index=get.index, get_distance=get.distance)),
        BPPARAM=BPPARAM, SIMPLIFY=FALSE)

    # Aggregating results across cores.
    output <- list()
    if (get.index) {
        neighbors <- .combine_matrices(collected, i=1, reorder=reorder)
        if (exact && !raw.index) {
            neighbors[] <- bnorder(precomputed)[neighbors]
        }
        output$index <- neighbors
    } 
    if (get.distance) {
        output$distance <- .combine_matrices(collected, i=2, reorder=reorder)
    }

    output
}

.setup_query <- function(query, transposed, subset, distance="Euclidean") 
# Convenience wrapper to set up the query.
{
    query <- .coerce_matrix_build(query, transposed)
    if (distance=="Cosine") {
        query <- l2norm(query)
    }

    # Choosing indices.
    if (!is.null(subset)) {
        job.id <- .subset_to_index(subset, query, byrow=FALSE)
        reorder <- order(job.id) # ordering so that queries are adjacent.
        job.id <- job.id[reorder]
    } else {
        job.id <- seq_len(ncol(query))
        reorder <- NULL
    }
    list(query=query, index=job.id, reorder=reorder)
}
