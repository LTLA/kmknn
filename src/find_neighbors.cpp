#include "objects.h"
#include "utils.h"

SEXP find_neighbors(SEXP to_check, SEXP X, SEXP clust_centers, SEXP clust_info, SEXP dist_thresh, SEXP get_index, SEXP get_distance) {
    BEGIN_RCPP
    auto searcher=generate_holder(X, clust_centers, clust_info);
    const double threshold=check_numeric_scalar(dist_thresh, "threshold");
  
    // Figuring out which indices we're using.
    const size_t total_obs=searcher->get_nobs();
    const Rcpp::IntegerVector points(to_check);
    for (auto h : points) {
        if (h==NA_INTEGER || h < 0 || h >= total_obs) {
            throw std::runtime_error("job indices out of range");
        }
    }
    const size_t nobs=points.size();

    // Getting the output mode.
    const bool store_neighbors=check_logical_scalar(get_index, "'get.index'");
    const bool store_distances=check_logical_scalar(get_distance, "'get.distance'");

    Rcpp::List out_dist;
    if (store_distances) {
        out_dist=Rcpp::List(nobs);
    }

    Rcpp::List out_idx;
    if (store_neighbors) {
        out_idx=Rcpp::List(nobs);
    }

    // Iterating across cells, finding NNs and storing distances or neighbors.
    size_t ix=0;
    for (auto h : points) {
        searcher->find_neighbors(h, threshold, store_distances);

        if (store_neighbors) {
            const std::deque<size_t>& neighbors=searcher->get_neighbors();
            Rcpp::IntegerVector output(neighbors.begin(), neighbors.end());
            for (auto& o : output) { ++o; } // getting back to 1-based indexing.
            out_idx[ix]=output;
        }

        if (store_neighbors) {
            const std::deque<double>& distances=searcher->get_distances();
            out_dist[ix]=Rcpp::NumericVector(distances.begin(), distances.end());
        }
        ++ix;
    }

    return Rcpp::List::create(out_idx, out_dist);
    END_RCPP
}
