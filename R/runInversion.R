#' Run PROSPECT inversion
#'
#' @inheritParams initModel
#' @inheritParams getSpectra
#' @param custom_invert_options List of invert_options to modify
#' @inheritDotParams PEcAnRTM::invert.auto
#' @export
runInversion <- function(db, samplecode, modelname, custom_invert_options = NULL, ...) {
    rtm_list <- list('PROSPECT 4' = function(param) prospect(param = param, version = 4)[,1],
                     'PROSPECT 5' = function(param) prospect(param = param, version = 5)[,1],
                     'PROSPECT 5B' = function(param) prospect(param = param, version = "5B")[,1])
    if (!modelname %in% names(rtm_list)) {
        stop('modelname ', shQuote(modelname), ' not found. ',
             'Please select one of the following: ',
             paste(names(rtm_list), collapse = ', '))
    }
    rtm <- rtm_list[[modelname]]
    # Load spectra from database
    specdata <- getSpectra(db, samplecode)
    if (is.null(specdata)) {
        warning('No spectra found. Returning NULL')
        return(NULL)
    }
    spectratype <- attr(specdata, 'spectratype')
    # Define default invert options
    invert_options <- list(nchains = 5,
                           ngibbs.max = 1e7,
                           ngibbs.min = 5000,
                           ngibbs.step = 2500,
                           return.samples = TRUE,
                           target = 0.234,
                           do.lsq = FALSE,
                           save.samples = NULL,
                           quiet = FALSE,
                           adapt = 250,
                           adj_min = 0.05)
    if (spectratype == 'pseudo-absorbance') {
        model_allwl <- function(param) log10(1/rtm(param))
    } else {
        model_allwl <- function(param) rtm(param)
    }
    param.mins <- c('N' = 1, 'Cab' = 0, 'Car' = 0, 'Cbrown' = 0,'Cw' = 0, 'Cm' = 0)
    param.maxs <- c('N' = Inf, 'Cab' = Inf, 'Car' = Inf, 'Cbrown' = Inf, 'Cw' = Inf, 'Cm' = Inf)
    prior_vals <- prior.defaultvals.prospect()
    # Uninformative prior on Cbrown
    prior_vals$mu <- c(prior_vals$mu, 'Cbrown' = 0)
    prior_vals$sigma <- c(prior_vals$sigma, 'Cbrown' = 1)
    params <- list('PROSPECT 4' = params.prospect4,
                   'PROSPECT 5' = params.prospect5,
                   'PROSPECT 5B' = params.prospect5b)[[modelname]]
    npar <- length(params)
    prior_mu <- prior_vals$mu[params]
    prior_sigma <- prior_vals$sigma[params]
    invert_options$param.mins <- param.mins[params]
    invert_options$param.maxs <- param.maxs[params]
    invert_options$inits.function <- function() {
        rlnorm(npar, prior_mu, prior_sigma) + invert_options$param.mins
    }
    invert_options$prior.function <- function(params) {
        parm1 <- params - invert_options$param.mins
        sum(dlnorm(parm1, prior_mu, prior_sigma, log = TRUE))
    }

    # Identify wavelengths and align
    prospect_wl_min <- 400
    prospect_wl_max <- 2500
    specdata_sub <- filter_(specdata,
                            ~wavelength >= prospect_wl_min,
                            ~wavelength <= prospect_wl_max)
    wavelength_indices <- 1 + specdata_sub[['wavelength']] - prospect_wl_min
    invert_options$model <- function(params) model_allwl(params)[wavelength_indices]

    observed <- select_(specdata, ~-wavelength) %>% as.matrix()

    test_param <- invert_options$inits.function()
    test_sim <- invert_options$model(test_param)
    test_diff <- observed - test_sim
    if (any(dim(test_diff) != dim(observed))) {
        stop('Dimension mismatch between test_diff (', 
             paste(dim(test_diff), collapse = ', '),
             ') and observed (',
             paste(dim(observed), collapse = ', '), ')')
    }

    # Modify invert_options with custom options
    if (!is.null(custom_invert_options)) {
        invert_options <- modifyList(invert_options, custom_invert_options)
    }

    # Run inversion
    results <- invert.auto(observed = observed, invert.options = invert_options, ...)
    return(results)
}

#samplecode <- "accp|89BE1|1989"
