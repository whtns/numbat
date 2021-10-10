require(extraDistr)
require(poilog)

cnv_colors = c("neu" = "gray",
        "del_up" = "royalblue", "del_down" = "darkblue", 
        "loh_up" = "darkgreen", "loh_down" = "olivedrab4",
        "amp_up" = "red", "amp_down" = "tomato3",
        "del_1_up" = "royalblue", "del_1_down" = "darkblue", 
        "loh_1_up" = "darkgreen", "loh_1_down" = "olivedrab4",
        "amp_1_up" = "red", "amp_1_down" = "tomato3",
        "del_2_up" = "royalblue", "del_2_down" = "darkblue", 
        "loh_2_up" = "darkgreen", "loh_2_down" = "olivedrab4",
        "amp_2_up" = "red", "amp_2_down" = "tomato3",
        "del_up_1" = "royalblue", "del_down_1" = "darkblue", 
        "loh_up_1" = "darkgreen", "loh_down_1" = "olivedrab4",
        "amp_up_1" = "red", "amp_down_1" = "tomato3",
        "del_up_2" = "royalblue", "del_down_2" = "darkblue", 
        "loh_up_2" = "darkgreen", "loh_down_2" = "olivedrab4",
        "amp_up_2" = "red", "amp_down_2" = "tomato3",
        "bamp" = "salmon", "bdel" = "skyblue",
        "amp" = "red", "loh" = "green", "del" = "darkblue", "neu2" = "gray30",
        "theta_up" = "darkgreen", "theta_down" = "olivedrab4",
        "theta_1_up" = "darkgreen", "theta_1_down" = "olivedrab4",
        "theta_2_up" = "darkgreen", "theta_2_down" = "olivedrab4",
        "theta_up_1" = "darkgreen", "theta_down_1" = "olivedrab4",
        "theta_up_2" = "darkgreen", "theta_down_2" = "olivedrab4",
        '0|1' = 'red', '1|0' = 'blue'
    )
    
############ time homogenous univariate HMM ############

run_hmm = function(pAD, DP, p_0 = 1-1e-5, p_s = 0.1) {
    
    # states
    states = c("theta_up", "neu", "theta_down")
    
    # transition matrix
    A <- matrix(
        c(p_0 * (1-p_s), 1 - p_0, p_0 * p_s, 
         (1-p_0)/2, p_0, (1-p_0)/2,
         p_0 * p_s, 1-p_0, p_0 * (1 - p_s)),
        ncol = length(states),
        byrow = TRUE
    )

    # intitial probabilities
    prior = rep(1/length(states), length(states))
    
    hmm = HiddenMarkov::dthmm(
            x = pAD, 
            Pi = A, 
            delta = prior, 
            distn = "bbinom",
            pm = list(alpha=c(10,10,6), beta=c(6,10,10)),
            pn = list(size = DP),
            discrete=TRUE)
    
    solution = states[HiddenMarkov::Viterbi(hmm)]
    
    return(solution)
}

############ time inhomogenous univariate HMM ############

Viterbi.dthmm.inhom <- function (obj, ...){
#     print('Solving univariate nonhomogenous markov chain')
    x <- obj$x
    dfunc <- HiddenMarkov:::makedensity(obj$distn)
    n <- length(x)
    m <- nrow(obj$Pi[[1]])
    nu <- matrix(NA, nrow = n, ncol = m)
    y <- rep(NA, n)

    nu[1, ] <- log(obj$delta) 

    if (!is.na(x[1])) {
        nu[1, ] <- nu[1, ] + dfunc(x=x[1], obj$pm, HiddenMarkov:::getj(obj$pn, 1), log=TRUE)
    }
    
    logPi <- lapply(obj$Pi, log)

    for (i in 2:n) {
        matrixnu <- matrix(nu[i - 1, ], nrow = m, ncol = m)
        nu[i, ] <- apply(matrixnu + logPi[[i]], 2, max)
        if (!is.na(x[i])) {
            nu[i, ] <- nu[i, ] + dfunc(x=x[i], obj$pm, HiddenMarkov:::getj(obj$pn, i), log=TRUE)
        }
    }
#     if (any(nu[n, ] == -Inf)) 
#         stop("Problems With Underflow")
    y[n] <- which.max(nu[n, ])
    # double check this index of logPi
    for (i in seq(n - 1, 1, -1)) y[i] <- which.max(logPi[[i + 1]][, y[i + 1]] + nu[i, ])
    
    return(y)
}

# one theta level
run_hmm_inhom = function(pAD, DP, p_s, t = 1e-5, theta_min = 0.08, gamma = 20, prior = NULL) {

    gamma = unique(gamma)

    if (length(gamma) > 1) {
        stop('More than one gamma parameter')
    }
    
    # states
    states = c("theta_up", "neu", "theta_down")
    
    # transition matrices
    calc_trans_mat = function(p_s, t, n_states) {
        matrix(
            c((1-t) * (1-p_s), t, (1-t) * p_s, 
             t/2, (1-t), t/2,
             (1-t) * p_s, t, (1-t) * (1-p_s)),
            ncol = n_states,
            byrow = TRUE
        )
    }
    
    As = lapply(
        p_s,
        function(p_s) {calc_trans_mat(p_s, t, n_states = length(states))}
    )
    
    # intitial probabilities
    if (is.null(prior)) {
        prior = rep(1/length(states), length(states))
    }

    alpha_up = (0.5 + theta_min) * gamma
    beta_up = (0.5 - theta_min) * gamma
    alpha_down = beta_up
    beta_down = alpha_up
    alpha_neu = gamma/2
    beta_neu = gamma/2
        
    hmm = HiddenMarkov::dthmm(
        x = pAD, 
        Pi = As, 
        delta = prior, 
        distn = "bbinom",
        pm = list(alpha=c(alpha_up,alpha_neu,alpha_down), beta=c(beta_up,beta_neu,beta_down)),
        pn = list(size = DP),
        discrete = TRUE)

    class(hmm) = 'dthmm.inhom'
        
    solution = states[HiddenMarkov::Viterbi(hmm)]
    
    return(solution)
}

# two theta levels
run_hmm_inhom2 = function(pAD, DP, p_s, t = 1e-5, theta_min = 0.08, gamma = 20, prior = NULL) {

    gamma = unique(gamma)

    if (length(gamma) > 1) {
        stop('More than one gamma parameter')
    }
    
    # states
    states = c("neu", "theta_1_up", "theta_1_down", "theta_2_up", "theta_2_down")
    
    # transition matrices
    calc_trans_mat = function(p_s, t, n_states) {
        matrix(
            c(1-t, t/4, t/4, t/4, t/4, 
             t/4, (1-t)*(1-p_s), (1-t)*p_s, t/4, t/4,
             t/4, (1-t)*p_s, (1-t)*(1-p_s), t/4, t/4,
             t/4, t/4, t/4, (1-t)*(1-p_s), (1-t)*p_s,
             t/4, t/4, t/4, (1-t)*p_s, (1-t)*(1-p_s)),
            ncol = n_states,
            byrow = TRUE
        )
    }
    
    As = lapply(
        p_s,
        function(p_s) {calc_trans_mat(p_s, t, n_states = length(states))}
    )
    
    # intitial probabilities
    if (is.null(prior)) {
        prior = rep(1/length(states), length(states))
    }

    theta_1 = theta_min
    theta_2 = 0.4
            
    hmm = HiddenMarkov::dthmm(
        x = pAD, 
        Pi = As, 
        delta = prior, 
        distn = "bbinom",
        pm = list(
            alpha = gamma * c(0.5, 0.5 + theta_1, 0.5 - theta_1, 0.5 + theta_2, 0.5 - theta_2),
            beta = gamma * c(0.5, 0.5 - theta_1, 0.5 + theta_1, 0.5 - theta_2, 0.5 + theta_2)
        ),
        pn = list(size = DP),
        discrete = TRUE
    )

    class(hmm) = 'dthmm.inhom'
        
    solution = states[HiddenMarkov::Viterbi(hmm)]
    
    return(solution)
}


forward_back_allele = function (obj, ...) {
    
    x <- obj$x
    p_x <- HiddenMarkov:::makedensity(obj$distn)
    
    m <- nrow(obj$Pi[[1]])
    n <- length(x)
    
    logprob = sapply(1:m, function(k) {
        
        l_x = p_x(x = x,  HiddenMarkov:::getj(obj$pm, k), obj$pn, log = TRUE)
        
        l_x[is.na(l_x)] = 0
        
        return(l_x)
        
    })
        
    logphi <- log(as.double(obj$delta))
    logalpha <- matrix(as.double(rep(0, m * n)), nrow = n)
    lscale <- as.double(0)
    logPi <- lapply(obj$Pi, log)
    
    for (t in 1:n) {
        
        if (t > 1) {
            logphi <- sapply(1:m, function(j) matrixStats::logSumExp(logphi + logPi[[t]][,j]))
        }
                          
        logphi <- logphi + logprob[t,]
                          
        logsumphi <- matrixStats::logSumExp(logphi)
                          
        logphi <- logphi - logsumphi
                          
        lscale <- lscale + logsumphi
                          
        logalpha[t,] <- logphi + lscale
                          
        LL <- lscale
    }

    logbeta <- matrix(as.double(rep(0, m * n)), nrow = n)
    logphi <- log(as.double(rep(1/m, m)))
    lscale <- as.double(log(m))

    for (t in seq(n-1, 1, -1)){
        
        logphi = sapply(1:m, function(i) matrixStats::logSumExp(logphi + logprob[t+1,] + logPi[[t+1]][i,]))

        logbeta[t,] <- logphi + lscale

        logsumphi <- matrixStats::logSumExp(logphi)

        logphi <- logphi - logsumphi

        lscale <- lscale + logsumphi
    }
    
    return(list('logalpha' = logalpha, 'logbeta' = logbeta))
}

# only compute total log likelihood
likelihood_allele = function (obj, ...) {
        
    x <- obj$x
    p_x <- HiddenMarkov:::makedensity(obj$distn)
    
    m <- nrow(obj$Pi[[1]])
    n <- length(x)
    
    logprob = sapply(1:m, function(k) {
        
        l_x = p_x(x = x,  HiddenMarkov:::getj(obj$pm, k), obj$pn, log = TRUE)
        
        l_x[is.na(l_x)] = 0
        
        return(l_x)
        
    })
        
    logphi <- log(as.double(obj$delta))

    logalpha <- matrix(as.double(rep(0, m * n)), nrow = n)
    
    LL <- as.double(0)
    
    logPi <- lapply(obj$Pi, log)
        
    for (i in 1:n) {
        
        if (i > 1) {
            logphi <- sapply(1:m, function(j) matrixStats::logSumExp(logphi + logPi[[i]][,j]))
        }
                             
        logphi <- logphi + logprob[i,]
                          
        logSumPhi <- matrixStats::logSumExp(logphi)
                          
        logphi <- logphi - logSumPhi
                                                                              
        LL <- LL + logSumPhi
                             
    }
    
    return(LL)
}

get_allele_hmm = function(pAD, DP, p_s, theta, gamma = 20) {

    states = c("theta_up", "theta_down")
    calc_trans_mat = function(p_s) {
        matrix(c(1 - p_s, p_s, p_s, 1 - p_s), ncol = 2, byrow = TRUE)
    }
    As = lapply(p_s, function(p_s) {
        calc_trans_mat(p_s)
    })
    prior = c(0.5, 0.5)
    alpha_up = (0.5 + theta) * gamma
    beta_up = (0.5 - theta) * gamma
    alpha_down = beta_up
    beta_down = alpha_up
    
    hmm = HiddenMarkov::dthmm(x = pAD, Pi = As, delta = prior, 
        distn = "bbinom", pm = list(alpha = c(alpha_up, alpha_down), 
            beta = c(beta_up, beta_down)), pn = list(size = DP), 
        discrete = TRUE)

    class(hmm) = "dthmm.inhom"

    return(hmm)
}
                             
calc_allele_lik = function (pAD, DP, p_s, theta, gamma = 20) {
    hmm = get_allele_hmm(pAD, DP, p_s, theta, gamma)
    LL = likelihood_allele(hmm)
    return(LL)
}


############ time homogenous multivariate HMM ############

Viterbi.dthmm.mv <- function (obj, ...){
#     print('running multivariate HMM')
    x <- obj$x
    dfunc <- HiddenMarkov:::makedensity(obj$distn)
    
    y <- obj$y
    p_y <- HiddenMarkov:::makedensity(obj$distn_y)
    
    n <- length(x)
    m <- nrow(obj$Pi)
    nu <- matrix(NA, nrow = n, ncol = m)
    y <- rep(NA, n)
    
    nu[1, ] = log(obj$delta)
    
    if (!is.na(x[1])) {
        nu[1, ] = nu[1, ] + dfunc(x=x[1], obj$pm, HiddenMarkov:::getj(obj$pn, 1), log=TRUE)
    }
    
    if (!is.na(y[1])) {
        nu[1, ] = nu[1, ] + p_y(x=y[1], obj$pm2, HiddenMarkov:::getj(obj$pn2, 1), log=TRUE)
    }
        
    logPi <- log(obj$Pi)

    for (i in 2:n) {
        matrixnu <- matrix(nu[i - 1, ], nrow = m, ncol = m)
        
        nu[i, ] = apply(matrixnu + logPi, 2, max)
            
        if (!is.na(x[i])) {
            nu[i, ] = nu[i, ] + dfunc(x=x[i], obj$pm, HiddenMarkov:::getj(obj$pn, i), log=TRUE)
        }
        
        if (!is.na(y[i])) {
            nu[i, ] = nu[i, ] + p_y(x=y[i], obj$pm2, HiddenMarkov:::getj(obj$pn2, i), log=TRUE)
        }
    }
    
    if (any(nu[n, ] == -Inf)) 
        stop("Problems With Underflow")
    y[n] <- which.max(nu[n, ])
    for (i in seq(n - 1, 1, -1)) y[i] <- which.max(logPi[, y[i + 1]] + nu[i, ])
    return(y)
}

run_hmm_mv = function(pAD, DP, exp, sigma, mu_neu, mu_del, mu_gain, p_0 = 1-1e-5, p_s = 0.1) {
    
    # states
    states = c("1" = "neu", "2" = "del_up", "3" = "del_down", "4" = "loh_up",
               "5" = "loh_down", "6" = "amp_up", "7" = "amp_down")

    # intitial probabilities
    prior = rep(1/length(states), length(states))

    # transition matrix
    A <- matrix(
        c(
            p_0, rep((1-p_0)/6, 6),
            (1-p_0)/5, p_0 * (1 - p_s), p_0 * p_s, rep((1-p_0)/5, 4),
            (1-p_0)/5, p_0 * p_s, p_0 * (1 - p_s), rep((1-p_0)/5, 4),
            rep((1-p_0)/5, 3), p_0 * (1 - p_s), p_0 * p_s, rep((1-p_0)/5, 2),
            rep((1-p_0)/5, 3), p_0 * p_s, p_0 * (1 - p_s), rep((1-p_0)/5, 2),
            rep((1-p_0)/5, 5), p_0 * (1 - p_s), p_0 * p_s,
            rep((1-p_0)/5, 5), p_0 * p_s, p_0 * (1 - p_s)
        ),
        ncol = length(states),
        byrow = TRUE
    )
    
    hmm = HiddenMarkov::dthmm(
        x = pAD, 
        Pi = A, 
        delta = prior, 
        distn = "bbinom",
        pm = list(alpha = c(10, rep(c(10, 6), 3)), beta = c(10, rep(c(6, 10), 3))),
        pn = list(size = DP),
        discrete = TRUE
    )

    hmm$distn_y = 'norm'
    hmm$y = exp
    hmm$pm2 = list(mean = c(mu_neu, rep(mu_del, 2), rep(mu_neu, 2), rep(mu_gain, 2)), sd = rep(sigma, 7))
    
    class(hmm) = 'dthmm.mv'

    return(states[as.character(HiddenMarkov::Viterbi(hmm))])
}

############ time inhomogenous multivariate HMM ############

Viterbi.dthmm.mv.inhom.gpois <- function (object, ...){

    x <- object$x
    dfunc <- HiddenMarkov:::makedensity(object$distn)
    
    x2 <- object$x2
    dfunc2 <- HiddenMarkov:::makedensity(object$distn2)

    n <- length(x)
    m <- nrow(object$Pi[[1]])
    nu <- matrix(NA, nrow = n, ncol = m)
    mu <- matrix(NA, nrow = n, ncol = m + 1)
    y <- rep(NA, n)
    
    
    nu[1, ] = log(object$delta)
    
        
    if (!is.na(x[1])) {
        nu[1, ] = nu[1, ] + dfunc(x=x[1], object$pm, HiddenMarkov:::getj(object$pn, 1), log = TRUE)
    }
    
    if (!is.na(x2[1])) {

        nu[1, ] = nu[1, ] + dfunc2(
            x = x2[1],
            list('shape' = object$alpha[1]),
            list('rate' = object$beta[1]/(object$phi * object$d * object$lambda_star[1])),
            log = TRUE
        )
        
    }
            
    logPi <- lapply(object$Pi, log)

    for (i in 2:n) {
        matrixnu <- matrix(nu[i - 1, ], nrow = m, ncol = m)
        
        nu[i, ] = apply(matrixnu + logPi[[i]], 2, max)
            
        if (!is.na(x[i])) {
            nu[i, ] = nu[i, ] + dfunc(x=x[i], object$pm, HiddenMarkov:::getj(object$pn, i), log = TRUE)
        }
        
        if (!is.na(x2[i])) {
            nu[i, ] = nu[i, ] + dfunc2(
                x = x2[i],
                list('shape' = object$alpha[i]),
                list('rate' = object$beta[i]/(object$phi * object$d * object$lambda_star[i])),
                log = TRUE
            )
            
        }
    }
    
    # if (any(nu[n, ] == -Inf)) {
    #     stop("Problems With Underflow")
    # }
    # display(tail(nu, 100))
    # fwrite(nu, '~/debug.txt')
              
    y[n] <- which.max(nu[n, ])

    for (i in seq(n - 1, 1, -1)) y[i] <- which.max(logPi[[i+1]][, y[i+1]] + nu[i, ])
        
    return(y)
}

Viterbi.dthmm.mv.inhom.lnpois <- function (object, ...){

    x <- object$x
    dfunc <- HiddenMarkov:::makedensity(object$distn)
    
    x2 <- object$x2
    dfunc2 <- HiddenMarkov:::makedensity(object$distn2)

    n <- length(x)
    m <- nrow(object$Pi[,,1])
    nu <- matrix(NA, nrow = n, ncol = m)
    mu <- matrix(NA, nrow = n, ncol = m + 1)
    y <- rep(NA, n)
    
    nu[1, ] = log(object$delta)
    
        
    if (!is.na(x[1])) {
        nu[1, ] = nu[1, ] + dfunc(x=x[1], object$pm, HiddenMarkov:::getj(object$pn, 1), log = TRUE)
    }
    
    if (!is.na(x2[1])) {

        nu[1, ] = nu[1, ] + dfunc2(
            x = rep(x2[1], m),
            list('sig' = rep(object$sig[1], m)),
            list('mu' = object$mu[1] + log(object$phi * object$d * object$lambda_star[1])),
            log = TRUE
        )
        
    }
            
    logPi <- log(object$Pi)

    for (i in 2:n) {
        matrixnu <- matrix(nu[i - 1, ], nrow = m, ncol = m)
        
        nu[i, ] = apply(matrixnu + logPi[,,i], 2, max)
            
        if (!is.na(x[i])) {
            nu[i, ] = nu[i, ] + dfunc(x=x[i], object$pm, HiddenMarkov:::getj(object$pn, i), log = TRUE)
        }
        
        if (!is.na(x2[i])) {
            nu[i, ] = nu[i, ] + dfunc2(
                x = rep(x2[i], m),
                list('sig' = rep(object$sig[i], m)),
                list('mu' = object$mu[i] + log(object$phi * object$d * object$lambda_star[i])),
                log = TRUE
            )
        }
    }

    if (any(is.na(nu))) {
        # fwrite(nu, '~/debug.txt')
        stop("NA values in viterbi")
    }
    
    if (all(nu[n, ] == -Inf)) {
        # fwrite(nu, '~/debug.txt')
        stop("Problems With Underflow")
    }

    # fwrite(nu, '~/debug.txt')
              
    y[n] <- which.max(nu[n, ])

    for (i in seq(n - 1, 1, -1)) y[i] <- which.max(logPi[,,i+1][, y[i+1]] + nu[i, ])
        
    return(y)
}

forward.mv.inhom = function (obj, ...) {
    
    x <- obj$x
    p_x <- HiddenMarkov:::makedensity(obj$distn)
    
    y <- obj$y
    p_y <- HiddenMarkov:::makedensity(obj$distn_y)
    
    m <- nrow(obj$Pi[[1]])
    n <- length(x)
    
    logprob = sapply(1:m, function(k) {
        
        l_x = p_x(x = x,  HiddenMarkov:::getj(obj$pm, k), obj$pn, log = TRUE)
        
        l_x[is.na(l_x)] = 0
        
        l_y = p_y(
                x = y,
                list('shape' = obj$alpha),
                list('rate' = obj$beta/(obj$phi[k] * obj$d * obj$lambda_star)),
                log = TRUE
            )
        
        l_y[is.na(l_y)] = 0
        
        return(l_x + l_y)
        
    })
        
    logphi <- log(as.double(obj$delta))

    logalpha <- matrix(as.double(rep(0, m * n)), nrow = n)
    
    lscale <- as.double(0)
    
    logPi <- lapply(obj$Pi, log)
    
    for (i in 1:n) {
        
        if (i > 1) {
            logphi <- sapply(1:m, function(j) matrixStats::logSumExp(logphi + logPi[[i]][,j]))
        }
                          
        logphi <- logphi + logprob[i,]
                          
        logSumPhi <- matrixStats::logSumExp(logphi)
                          
        logphi <- logphi - logSumPhi
                          
        lscale <- lscale + logSumPhi
                          
        logalpha[i,] <- logphi + lscale
                          
        LL <- lscale
    }
    
    return(LL)
}

get_trans_probs = function(t, p_s, w, cn_from, phase_from, cn_to, phase_to) {

    if (cn_from == cn_to) {
        if (is.na(phase_from) & is.na(phase_to)) {
            p = 1-t
            p = rep(p, length(p_s))
        } else if (phase_from == phase_to) {
            p = (1-t) * (1-p_s)
        } else {
            p = (1-t) * p_s
        }
    } else {
        p = t * w[[cn_to]]/sum(w[names(w)!=cn_from])
        if (!is.na(phase_to)) {
            p = p/2
        }
        p = rep(p, length(p_s))
    }
    
    return(p)
}

calc_trans_mat = function(t, p_s, w, states_cn, states_phase) {

    sapply(1:length(states_cn), function(from) {
        sapply(1:length(states_cn), function(to) {
            get_trans_probs(t, p_s, w, states_cn[from], states_phase[from], states_cn[to], states_phase[to])
        }) %>% t
    }) %>% t %>%
    array(dim = c(length(states_cn), length(states_cn), length(p_s)))

}

run_hmm_mv_inhom = function(
    pAD, DP, p_s, Y_obs, lambda_ref, d_total, theta_min = 0.08, theta_neu = 0, bal_cnv = TRUE, phi_neu = 1, phi_del = 2^(-0.25), phi_amp = 2^(0.25), phi_bamp = 2^(0.25), phi_bdel = 2^(-0.25), 
    alpha = 1, beta = 1, 
    mu = 0, sig = 1,
    exp_model = 'gpois',
    t = 1e-5, gamma = 18, prior = NULL, exp_only = FALSE, allele_only = FALSE, classify_allele = FALSE, phasing = TRUE, debug = FALSE
) {

    # states
    states = c(
        "1" = "neu", "2" = "del_1_up", "3" = "del_1_down", "4" = "del_2_up", "5" = "del_2_down",
        "6" = "loh_1_up", "7" = "loh_1_down", "8" = "loh_2_up", "9" = "loh_2_down", 
        "10" = "amp_1_up", "11" = "amp_1_down", "12" = "amp_2_up", "13" = "amp_2_down", 
        "14" = "bamp", "15" = "bdel"
    )

    states_cn = str_remove(states, '_up|_down')
    states_phase = str_extract(states, 'up|down')

    # relative abundance of states
    w = c('neu' = 1, 'del_1' = 1, 'del_2' = 1e-10, 'loh_1' = 1, 'loh_2' = 1e-10, 'amp_1' = 1, 'amp_2' = 1e-10, 'bamp' = 1e-4, 'bdel' = 1e-10)
        
    # intitial probabilities
    if (is.null(prior)) {
        # encourage CNV from telomeres
        prior = sapply(1:length(states), function(to){
                get_trans_probs(
                    t = min(t * 100, 1), p_s = 0, w,
                    cn_from = 'neu', phase_from = NA,
                    cn_to = states_cn[to], phase_to = states_phase[to])
            })
    }

    # to do: renormalize the probabilities after deleting states
    states_index = 1:length(states)

    if (!bal_cnv) {
        states_index = 1:13
    }
        
    if (exp_only) {
        pAD = rep(NA, length(pAD))
        p_s = rep(0, length(p_s))
    }
    
    if (allele_only) {
        states_index = c(1, 6:9)

        Y_obs = rep(NA, length(Y_obs))
    }

    if (!phasing) {
        states_index = c(1, 6)
        
        p_s = ifelse(is.na(pAD), p_s, 0)
        pAD = ifelse(pAD > (DP - pAD), pAD, DP - pAD)
        theta_neu = 0.1
        theta_min = 0.45
    }

    if (classify_allele) {
        states_index = c(6,7)
    }
    
    # transition matrices
    As = calc_trans_mat(t, p_s, w, states_cn, states_phase)

    theta_u_1 = 0.5 + theta_min
    theta_d_1 = 0.5 - theta_min

    theta_u_2 = 0.9
    theta_d_2 = 0.1

    theta_u_neu = 0.5 + theta_neu
    theta_d_neu = 0.5 - theta_neu

    # parameters for each state
    alpha_states = gamma * c(theta_u_neu, rep(c(theta_u_1, theta_d_1, theta_u_2, theta_d_2), 3), theta_u_neu, theta_u_neu)
    beta_states = gamma * c(theta_d_neu, rep(c(theta_d_1, theta_u_1, theta_d_2, theta_u_2), 3), theta_d_neu, theta_d_neu)
    phi_states = c(phi_neu, rep(phi_del, 2), rep(0.5, 2), rep(phi_neu, 4), rep(phi_amp, 2), rep(2.5, 2), phi_bamp, phi_bdel)

    prior = prior[states_index]
    As = As[states_index, states_index,]
    alpha_states = alpha_states[states_index]
    beta_states = beta_states[states_index]
    phi_states = phi_states[states_index]
    states = states[states_index] %>% setNames(1:length(.))
                
    hmm = HiddenMarkov::dthmm(
        x = pAD, 
        Pi = As, 
        delta = prior, 
        distn = "bbinom",
        pm = list(
            alpha = alpha_states,
            beta = beta_states
        ),
        pn = list(size = DP),
        discrete = TRUE
    )

    hmm$x2 = Y_obs
    hmm$phi = phi_states
    hmm$lambda_star = lambda_ref
    hmm$d = d_total

    if (exp_model == 'gpois') {

        # print('running gpois model')

        hmm$distn2 = 'gpois'
        hmm$alpha = alpha
        hmm$beta = beta
        
        class(hmm) = 'dthmm.mv.inhom.gpois'

    } else {

        if (length(mu) == 1 & length(sig) == 1) {
            mu = rep(mu, length(Y_obs))
            sig = rep(sig, length(Y_obs))
        }

        hmm$distn2 = 'poilog'
        hmm$mu = mu
        hmm$sig = sig
        
        class(hmm) = 'dthmm.mv.inhom.lnpois'

    }
        
    return(states[as.character(HiddenMarkov::Viterbi(hmm))])
}




run_hmm_mv_inhom_gpois = function(pAD, DP, p_s, Y_obs, lambda_ref, d_total, theta_min, bal_cnv = TRUE, phi_neu = 1, phi_del = 2^(-0.25), phi_amp = 2^(0.25), phi_bamp = 2^(0.25), phi_bdel = 2^(-0.25), alpha = 1, beta = 1, t = 1e-5, gamma = 18, prior = NULL, exp_only = FALSE, allele_only = FALSE, debug = FALSE) {
    
    # states
    states = c("1" = "neu", "2" = "del_up", "3" = "del_down", "4" = "loh_up", "5" = "loh_down", 
               "6" = "amp_up", "7" = "amp_down", "8" = "bamp", "9" = "bdel")
    
    # relative abundance of states
    w = c('neu' = 1, 'del' = 1, 'loh' = 1, 'amp' = 1, 'bamp' = 1e-4, 'bdel' = 1e-10)
        
    if (!bal_cnv) {
        w[c('bamp', 'bdel')] = 0
    }
    
    # intitial probabilities
    if (is.null(prior)) {
        # encourage CNV from telomeres
        a_0 = get_trans_probs(t = t * 100, w)[['neu']]
        prior = c(a_0[['neu']], 
            rep(a_0[['del']]/2, 2),
            rep(a_0[['loh']]/2, 2),
            rep(a_0[['amp']]/2, 2), 
            a_0[['bamp']],
            a_0[['bdel']])
    }
        
    if (exp_only) {
        pAD = rep(NA, length(pAD))
        p_s = rep(0, length(p_s))
    }
    
    if (allele_only) {
        Y_obs = rep(NA, length(Y_obs))
    }
    
    a = get_trans_probs(t, w)
    
    # transition matrices
    calc_trans_mat = function(p_s, t, n_states) {
        matrix(
            c(
                1-t, rep(a[['neu']][['del']]/2, 2), rep(a[['neu']][['loh']]/2, 2), rep(a[['neu']][['amp']]/2, 2), a[['neu']][['bamp']], a[['neu']][['bdel']],
                a[['del']][['neu']], (1-t)*(1-p_s), (1-t)*p_s, rep(a[['del']][['loh']]/2, 2), rep(a[['del']][['amp']]/2, 2), a[['del']][['bamp']], a[['del']][['bdel']],
                a[['del']][['neu']], (1-t)*p_s, (1-t)*(1-p_s), rep(a[['del']][['loh']]/2, 2), rep(a[['del']][['amp']]/2, 2), a[['del']][['bamp']], a[['del']][['bdel']],
                a[['loh']][['neu']], rep(a[['loh']][['del']]/2, 2), (1-t)*(1-p_s), (1-t)*p_s, rep(a[['loh']][['amp']]/2, 2), a[['loh']][['bamp']], a[['loh']][['bdel']],
                a[['loh']][['neu']], rep(a[['loh']][['del']]/2, 2), (1-t)*p_s, (1-t)*(1-p_s), rep(a[['loh']][['amp']]/2, 2), a[['loh']][['bamp']], a[['loh']][['bdel']],
                a[['amp']][['neu']], rep(a[['amp']][['del']]/2, 2), rep(a[['amp']][['loh']]/2, 2), (1-t)*(1-p_s), (1-t)*p_s, a[['amp']][['bamp']], a[['amp']][['bdel']],
                a[['amp']][['neu']], rep(a[['amp']][['del']]/2, 2), rep(a[['amp']][['loh']]/2, 2), (1-t)*p_s, (1-t)*(1-p_s), a[['amp']][['bamp']], a[['amp']][['bdel']],
                a[['bamp']][['neu']], rep(a[['bamp']][['del']]/2, 2), rep(a[['bamp']][['loh']]/2, 2), rep(a[['bamp']][['amp']]/2, 2), 1-t, a[['bamp']][['bdel']],
                a[['bdel']][['neu']], rep(a[['bdel']][['del']]/2, 2), rep(a[['bdel']][['loh']]/2, 2), rep(a[['bdel']][['amp']]/2, 2), a[['bdel']][['bamp']], 1-t
            ),
            ncol = n_states,
            byrow = TRUE
        )
    }
    
    As = lapply(
        p_s,
        function(p_s) {calc_trans_mat(p_s, t, n_states = length(states))}
    )
    
    theta_u = 0.5 + theta_min
    theta_d = 0.5 - theta_min
            
    hmm = HiddenMarkov::dthmm(
        x = pAD, 
        Pi = As, 
        delta = prior, 
        distn = "bbinom",
        pm = list(alpha = gamma * c(0.5, rep(c(theta_u, theta_d), 3), 0.5, 0.5), beta = gamma * c(0.5, rep(c(theta_d, theta_u), 3), 0.5, 0.5)),
        pn = list(size = DP),
        discrete = TRUE
    )
    
    hmm$distn2 = 'gpois'
    hmm$x2 = Y_obs
    hmm$phi = c(phi_neu, rep(phi_del, 2), rep(phi_neu, 2), rep(phi_amp, 2), phi_bamp, phi_bdel)
    hmm$alpha = alpha
    hmm$beta = beta
    hmm$lambda_star = lambda_ref
    hmm$d = d_total
    
    class(hmm) = 'dthmm.mv.inhom.gpois'
    
    if (debug) {
        return(hmm)
    }
    
    return(states[as.character(HiddenMarkov::Viterbi(hmm))])
}





