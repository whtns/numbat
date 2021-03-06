# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

cppdbbinom <- function(x, size, alpha, beta, log_prob = FALSE) {
    .Call('_numbat_cppdbbinom', PACKAGE = 'numbat', x, size, alpha, beta, log_prob)
}

logSumExp <- function(x) {
    .Call('_numbat_logSumExp', PACKAGE = 'numbat', x)
}

likelihood_compute <- function(logphi, logprob, logPi, n, m) {
    .Call('_numbat_likelihood_compute', PACKAGE = 'numbat', logphi, logprob, logPi, n, m)
}

forward_backward_compute <- function(logphi, logprob, logPi, n, m) {
    .Call('_numbat_forward_backward_compute', PACKAGE = 'numbat', logphi, logprob, logPi, n, m)
}

viterbi_compute <- function(log_delta, logprob, logPi, n, m, nu, z) {
    .Call('_numbat_viterbi_compute', PACKAGE = 'numbat', log_delta, logprob, logPi, n, m, nu, z)
}

fit_lnpois_cpp <- function(Y_obs, lambda_ref, d) {
    .Call('_numbat_fit_lnpois_cpp', PACKAGE = 'numbat', Y_obs, lambda_ref, d)
}

allChildrenCPP <- function(E) {
    .Call('_numbat_allChildrenCPP', PACKAGE = 'numbat', E)
}

CgetQ <- function(logQ, children_dict, node_order) {
    .Call('_numbat_CgetQ', PACKAGE = 'numbat', logQ, children_dict, node_order)
}

score_tree_cpp <- function(E, P) {
    .Call('_numbat_score_tree_cpp', PACKAGE = 'numbat', E, P)
}

score_nni_parallel <- function(trees, P) {
    .Call('_numbat_score_nni_parallel', PACKAGE = 'numbat', trees, P)
}

reorder_rows <- function(x, y) {
    .Call('_numbat_reorder_rows', PACKAGE = 'numbat', x, y)
}

reorderRcpp <- function(E) {
    .Call('_numbat_reorderRcpp', PACKAGE = 'numbat', E)
}

nnin_cpp <- function(E, n) {
    .Call('_numbat_nnin_cpp', PACKAGE = 'numbat', E, n)
}

nni_cpp <- function(tree) {
    .Call('_numbat_nni_cpp', PACKAGE = 'numbat', tree)
}

nni_cpp_parallel <- function(tree, P) {
    .Call('_numbat_nni_cpp_parallel', PACKAGE = 'numbat', tree, P)
}

poilog1 <- function(x, my, sig) {
    .Call('_numbat_poilog1', PACKAGE = 'numbat', x, my, sig)
}

l_lnpois_cpp <- function(Y_obs, lambda_ref, d, mu, sig, phi = 1.0) {
    .Call('_numbat_l_lnpois_cpp', PACKAGE = 'numbat', Y_obs, lambda_ref, d, mu, sig, phi)
}

