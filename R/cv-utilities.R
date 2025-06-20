#' Utility Functions for the cv Package
#'
#' These functions are primarily useful for writing methods for the
#' \code{\link{cv}()} generic function. They are used internally in the package
#' and can also be used for extensions (see the vignette "Extending the cv package,
#' \code{vignette("cv-extend", package="cv")}).
#'
#' @param model a regression model object.
#' @param data data frame to which the model was fit (not usually necessary,
#' except for \code{cvSelect()}).
#' @param criterion cross-validation criterion ("cost" or lack-of-fit) function of form \code{f(y, yhat)}
#'        where \code{y} is the observed values of the response and
#'        \code{yhat} the predicted values; the default is \code{\link{mse}}
#'        (the mean-squared error).
#' @param k perform k-fold cross-validation (default is \code{10}); \code{k}
#' may be a number or \code{"loo"} or \code{"n"} for n-fold (leave-one-out)
#' cross-validation; for \code{folds()}, \code{k} must be a number.
#' @param reps number of times to replicate k-fold CV (default is \code{1}).
#' @param confint if \code{TRUE} (the default if the number of cases is 400
#' or greater), compute a confidence interval for the bias-corrected CV
#' criterion, if the criterion is the average of casewise components.
#' @param level confidence level (default \code{0.95}).
#' @param seed for R's random number generator; optional, if not
#' supplied a random seed will be selected and saved; not needed
#' for n-fold cross-validation.
#' @param details if \code{TRUE} (the default if the number of
#' folds \code{k <= 10}), save detailed information about the value of the
#' CV criterion for the cases in each fold and the regression coefficients
#' with that fold deleted.
#' @param ncores number of cores to use for parallel computations
#'        (default is \code{1}, i.e., computations aren't done in parallel).
#' @param method computational method to apply; use by some \code{\link{cv}()}
#' methods.
#' @param type used by some \code{\link{cv}()} methods, such as the default method,
#' where \code{type} is passed to the \code{type} argument of \code{predict()};
#' the default is \code{type="response"}, which is appropriate, e.g., for a \code{"glm"} model
#' and may be recognized or ignored by \code{predict()} methods for other model classes.
#' @param start used by some \code{\link{cv}()} methods;
#' if \code{TRUE} (the default is \code{FALSE}), the \code{start} argument,
#' set to the vector of regression coefficients for the model fit to the full data, is passed
#' to \code{update()}, possibly making the CV updates faster, e.g. for a GLM.
#' @param n number of cases, for constructed folds.
#' @param folds an object of class \code{"folds"}.
#' @param i_ a fold number for an object of class \code{"folds"}.
#' @param ... to match generic; passed to \code{predict()} for the default method,
#' and to \code{fPara()} (for parallel computations) in \code{cvCompute()}.
#' @param f function to be called by \code{cvCompute()} for each fold.
#' @param fPara function to be called by \code{cvCompute()} for each fold
#' using parallel computation.
#' @param locals a named list of objects that are required in the local environment
#' of \code{cvCompute()} for \code{f()} or \code{fPara()}.
#' @param criterion.name a character string giving the name of the CV criterion function
#' in the returned \code{"cv"} object).
#' @param procedure a model-selection procedure function (see Details).
#' @param package the name of the package in which mixed-modeling function (or functions) employed resides;
#' used to get the namespace of the package.
#' @param clusterVariables a character vector of names of the variables
#' defining clusters for a mixed model with nested or crossed random effects;
#' if missing, cross-validation is performed for individual cases rather than
#' for clusters
#' @param predict.clusters.args a list of arguments to be used to predict
#' the whole data set from a mixed model when performing CV on clusters;
#' the first two elements should be
#' \code{model} and \code{newdata}; see the "Extending the cv package" vignette
#' (\code{vignette("cv-extend", package="cv")}).
#' @param predict.cases.args a list of arguments to be used to predict
#' the whole data set from a mixed model when performing CV on cases;
#' the first two elements should be
#' \code{model} and \code{newdata}; see the "Extending the cv package" vignette
#' (\code{vignette("cv-extend", package="cv")}).
#' @param fixed.effects a function to be used to compute fixed-effect
#' coefficients for cluster-based CV when \code{details = TRUE}.
#' @param save.coef save the coefficients from the selected models? Deprecated
#' in favor of the \code{details} argument; if specified, \code{details} is set
#' is set to the value of \code{save.coef}.
#' @param y.expression normally the response variable is found from the
#' \code{model} argument; but if, for a particular selection procedure, the
#' \code{model} argument is absent, or if the response can't be inferred from the
#' model, the response can be specified by an expression, such as \code{expression(log(income))},
#' to be evaluated within the data set provided by the \code{data} argument.
#' @param save.model save the model that's selected using the \emph{full} data set.
#' @param x a \code{"cv"}, \code{"cvList"}, or \code{"folds"} object to be printed
#' @param model.function a regression function, typically for a new \code{cv()} method,
#' residing in a package that's not a declared dependency of the \pkg{cv} package,
#' e.g., \code{nnet::multinom}.
#' @param model.function.name the quoted name of the regression function, e.g.,
#' \code{"multinom"}.

#' @returns
#' The utility functions return various kinds of objects:
#' \itemize{
#' \item \code{cvCompute()} returns an object of class \code{"cv"}, with the CV criterion
#' (\code{"CV crit"}), the bias-adjusted CV criterion (\code{"adj CV crit"}),
#' the criterion for the model applied to the full data (\code{"full crit"}),
#' the confidence interval and level for the bias-adjusted CV criterion (\code{"confint"}),
#' the number of folds (\code{"k"}), and the seed for R's random-number
#' generator (\code{"seed"}). If \code{details=TRUE}, then the returned object
#' will also include a \code{"details"} component, which is a list of two
#' elements: \code{"criterion"}, containing the CV criterion computed for the
#' cases in each fold; and \code{"coefficients"}, regression coefficients computed
#' for the model with each fold deleted.  Some \code{cv()} methods calling \code{cvCompute()}
#' may return a subset of these components and may add additional information.
#' If \code{reps} > \code{1}, then an object of class \code{"cvList"} is returned,
#' which is literally a list of \code{"cv"} objects.
#'
#' \item \code{cvMixed()} also returns an object of class \code{"cv"} or
#' \code{"cvList"}.
#'
#' \item \code{cvSelect} returns an object of class
#' \code{"cvSelect"} inheriting from \code{"cv"}, or an object of
#' class \code{"cvSelectList"} inheriting from \code{"cvList"}.
#'
#' \item \code{folds()} returns an object of class folds, for which
#' there are \code{fold()} and \code{print()} methods.
#'
#' \item \code{GetResponse()} returns the (numeric) response variable
#' from the model.
#'
#' The supplied \code{default} method returns the \code{model$y} component
#' of the model object, or, if \code{model} is an S4 object, the result
#' returned by the \code{\link[insight]{get_response}()} function in
#' the \pkg{insight} package. If this result is \code{NULL}, the result of
#' \code{model.response(model.frame(model))} is returned, checking in any case whether
#' the result is a numeric vector.
#'
#' There are also  \code{"lme"}, \code{"merMod"}
#' and \code{"glmmTMB"} methods that convert factor
#' responses to numeric 0/1 responses, as would be appropriate
#' for a generalized linear mixed model with a binary response.
#'
#' \item \code{checkFormula()} returns \code{TRUE} if all variables in the
#' model formula are also in the data to which the model is fit; \code{FALSE} is this
#' is not the case (and q warning is printed); or \code{NA} if the function
#' couldn't extract a model formula.
#'}
#' @examples
#' fit <- lm(mpg ~ gear, mtcars)
#' GetResponse(fit)
#'
#' set.seed(123)
#' (ffs <- folds(n=22, k=5))
#' fold(ffs, 2)
#'
#' @seealso \code{\link{cv}}, \code{\link{cv.merMod}},
#' \code{\link{cv.function}}.
#'
#' @describeIn cvCompute used internally by \code{cv()} methods (not for direct use);
#' exported to support new \code{cv()} methods.
#' @export
cvCompute <- function(model,
                      data = insight::get_data(model),
                      criterion = mse,
                      criterion.name,
                      k = 10L,
                      reps = 1L,
                      seed,
                      details = k <= 10L,
                      confint,
                      level = 0.95,
                      method = NULL,
                      ncores = 1L,
                      type = "response",
                      start = FALSE,
                      f,
                      fPara = f,
                      locals = list(),
                      model.function = NULL,
                      model.function.name = NULL,
                      ...) {

  checkFormula(model, colnames(data))

  # put function and variable args in the local environment
  env <- environment()
  environment(f) <- env
  environment(fPara) <- env
  localsNames <- names(locals)
  for (i_ in seq_along(locals)) {
    assign(localsNames[i_], locals[[i_]])
  }

  se.cv <- NA

  if (missing(criterion.name) ||
      is.null(criterion.name))
    criterion.name <- deparse(substitute(criterion))

  y <- GetResponse(model)
  b <- coef(model)
  n <- nrow(data)
  if (is.character(k)) {
    if (k == "n" || k == "loo") {
      k <- n
    }
  }
  if (!is.numeric(k) ||
      length(k) > 1L || k > n || k < 2L || k != round(k)) {
    stop('k must be an integer between 2 and n or "n" or "loo"')
  }
  if (k != n) {
    if (missing(seed) || is.null(seed))
      seed <- sample(1e6, 1L)
    set.seed(seed)
    message("R RNG seed set to ", seed)
  } else {
    if (reps > 1L)
      stop("reps should not be > 1 for n-fold CV")
    if (!missing(seed) &&
        !is.null(seed))
      message("Note: seed ignored for n-fold CV")
    seed <- NULL
  }
  folds <- folds(n, k)
  yhat <- if (is.factor(y)) {
    factor(rep(NA, n), levels = levels(y))
  } else if (is.character(y)) {
    character(n)
  } else {
    numeric(n)
  }

  if (details) {
    crit.i <- numeric(k)
    coef.i <- vector(k, mode = "list")
    names(crit.i) <- names(coef.i) <- paste("fold", 1L:k, sep = ".")
  } else {
    crit.i <- NULL
    coef.i <- NULL
  }

  if (ncores > 1L) {
    dots <- list(...)
    cl <- makeCluster(ncores)
    registerDoParallel(cl)
    result <- foreach(i_ = 1L:k) %dopar% {
      fPara(i_,
            model.function = model.function,
            model.function.name = model.function.name,
            ...)
    }
    stopCluster(cl)

    for (i_ in 1L:k) {
      yhat[fold(folds, i_)] <- result[[i_]]$fit.i
      if (details) {
        crit.i[i_] <- criterion(y[fold(folds, i_)],
                               yhat[fold(folds, i_)])
        coef.i[[i_]] <- result[[i_]]$coef.i
      }
    }
  } else {
    result <- vector(k, mode = "list")
    for (i_ in 1L:k) {
      result[[i_]] <- f(i_)
      yhat[fold(folds, i_)] <- result[[i_]]$fit.i
      if (details) {
        crit.i[i_] <- criterion(y[fold(folds, i_)],
                               yhat[fold(folds, i_)])
        coef.i[[i_]] <- result[[i_]]$coef.i
      }
    }
  }
  cv <- criterion(y, yhat)
  cv.full <- criterion(y, predict(model, type = type, ...))
  loss <- getLossFn(cv) # casewise loss function
  if (!is.null(loss)) {
    adj.cv <- cv + cv.full -
      weighted.mean(sapply(result, function(x)
        x$crit.all.i), folds$folds)
    se.cv <- sd(loss(y, yhat)) / sqrt(n)
    halfwidth <- qnorm(1 - (1 - level) / 2) * se.cv
    ci <-
      if (confint)
        c(
          lower = adj.cv - halfwidth,
          upper = adj.cv + halfwidth,
          level = round(level * 100)
        )
    else
      NULL
  } else {
    adj.cv <- NULL
    ci <- NULL
  }
  result <- list(
    "CV crit" = cv,
    "adj CV crit" = adj.cv,
    "full crit" = cv.full,
    "confint" = ci,
    "SE adj CV crit" = se.cv,
    "k" = if (k == n)
      "n"
    else
      k,
    "seed" = seed,
    "method" = method,
    "criterion" = criterion.name,
    "coefficients" = if (details) coef(model) else NULL,
    "details" = list(criterion = crit.i,
                     coefficients = coef.i)
  )
  if (missing(method) || is.null(method))
    result$method <- NULL
  class(result) <- "cv"
  if (reps == 1L) {
    return(result)
  } else {
    res <- cvCompute(
      model = model,
      data = data,
      criterion = criterion,
      criterion.name = criterion.name,
      k = k,
      reps = reps - 1L,
      details = details,
      confint = confint,
      level = level,
      method = method,
      ncores = ncores,
      type = type,
      start = start,
      f = f,
      fPara = fPara,
      locals = locals,
      model.function = model.function,
      model.function.name = model.function.name,
      ...
    )

    if (reps  > 2L) {
      res[[length(res) + 1L]] <- result
    } else {
      res <- list(res, result)
    }
    for (i_ in 1L:(length(res) - 1L)) {
      res[[i_]]["criterion"] <- res[[length(res)]]["criterion"]
    }
    class(res) <- "cvList"
    return(res)
  }
}

#' @describeIn cvCompute used internally by \code{cv()} methods
#' for mixed-effect models (not for direct use);
#' exported to support new \code{cv()} methods.
#' @export
cvMixed <- function(model,
                    package,
                    data = insight::get_data(model),
                    criterion = mse,
                    criterion.name,
                    k,
                    reps = 1L,
                    confint,
                    level = 0.95,
                    seed,
                    details,
                    ncores = 1L,
                    clusterVariables,
                    predict.clusters.args = list(object = model, newdata =
                                                   data),
                    predict.cases.args = list(object = model, newdata =
                                                data),
                    fixed.effects,
                    ...) {

  checkFormula(model, colnames(data))

  pkg.env <- getNamespace(package)

  se.cv <- NA

  if (missing(criterion.name) ||
      is.null(criterion.name))
    criterion.name <- deparse(substitute(criterion))

  f.clusters <-
    function(i_,
             predict.clusters.args,
             predict.cases.args,
             ...) {
      indices.i <- fold(folds, i_)
      index <-
        selectClusters(clusters[-indices.i, , drop = FALSE], data = data)
      update.args <- list(...)
      update.args$object <- model
      update.args$data <- data[index,]
      predict.clusters.args$object <-
        do.call(update, update.args, envir = pkg.env)
      fit.all.i <- do.call(predict, predict.clusters.args)
      fit.i <- fit.all.i[index <- !index]
      list(
        fit.i = fit.i,
        crit.all.i = criterion(y, fit.all.i),
        indices.i = index,
        coef.i = fixed.effects(predict.clusters.args$object)
      )
    }

  f.cases <-
    function(i_,
             predict.clusters.args,
             predict.cases.args,
             ...) {
      indices.i <- fold(folds, i_)
      update.args <- list(...)
      update.args$object <- model
      update.args$data <- data[-indices.i,]
      predict.cases.args$object <-
        do.call(update, update.args, envir = pkg.env)
      fit.all.i <- do.call(predict, predict.cases.args)
      fit.i <- fit.all.i[indices.i]
      list(
        fit.i = fit.i,
        crit.all.i = criterion(y, fit.all.i),
        indices.i = indices.i,
        coef.i = fixed.effects(predict.cases.args$object)
      )
    }
  y <- GetResponse(model)

  if (missing(clusterVariables))
    clusterVariables <- NULL
  if (is.null(clusterVariables)) {
    n <- nrow(data)
    if (missing(k) || is.null(k))
      k <- 10L
    if (is.character(k)) {
      if (k == "n" || k == "loo") {
        k <- n
      }
    }
    f <- f.cases
  } else {
    clusters <- defineClusters(clusterVariables, data)
    n <- nrow(clusters)
    if (missing(k) || is.null(k))
      k <- nrow(clusters)
    f <- f.clusters
  }

  if (!is.numeric(k) ||
      length(k) > 1L || k > n || k < 2L || k != round(k)) {
    stop("k must be an integer between 2 and number of",
         if (is.null(clusterVariables))
           "cases"
         else
           "clusters")
  }

  if (k != n) {
    if (missing(seed) || is.null(seed))
      seed <- sample(1e6, 1L)
    set.seed(seed)
    message("R RNG seed set to ", seed)
  } else {
    if (reps > 1L)
      stop("reps should not be > 1 for n-fold CV")
    if (!missing(seed) &&
        !is.null(seed))
      message("Note: seed ignored for n-fold CV")
    seed <- NULL
  }

  if (missing(details) || is.null(details))
    details <- k <= 10L

  if (details) {
    crit.i <- numeric(k)
    coef.i <- vector(k, mode = "list")
    names(crit.i) <- names(coef.i) <- paste("fold", 1L:k, sep = ".")
  } else {
    crit.i <- NULL
    coef.i <- NULL
  }

  folds <- folds(n, k)
  yhat <- if (is.factor(y)) {
    factor(rep(NA, n), levels = levels(y))
  } else if (is.character(y)) {
    character(n)
  } else {
    numeric(n)
  }

  if (ncores > 1L) {
    cl <- makeCluster(ncores)
    registerDoParallel(cl)
    result <- foreach(i_ = 1L:k) %dopar% {
      f(i_, predict.clusters.args, predict.cases.args, ...)
    }
    stopCluster(cl)
    for (i_ in 1L:k) {
      indices.i <- result[[i_]]$indices.i
      # yhat[result[[i]]$indices.i] <- result[[i]]$fit.i
      yhat[indices.i] <- result[[i_]]$fit.i
      if (details) {
        # crit.i[i] <- criterion(y[fold(folds, i)],
        #                        yhat[fold(folds, i)])
        crit.i[i_] <- criterion(y[indices.i],
                               yhat[indices.i])
        coef.i[[i_]] <- result[[i_]]$coef.i
      }
    }
  } else {
    result <- vector(k, mode = "list")
    for (i_ in 1L:k) {
      result[[i_]] <- f(i_, predict.clusters.args, predict.cases.args, ...)
      indices.i <- result[[i_]]$indices.i
      # yhat[result[[i]]$indices.i] <- result[[i]]$fit.i
      yhat[indices.i] <- result[[i_]]$fit.i
      if (details) {
        # crit.i[i] <- criterion(y[fold(folds, i)],
        #                        yhat[fold(folds, i)])
        crit.i[i_] <- criterion(y[indices.i],
                               yhat[indices.i])
        coef.i[[i_]] <- result[[i_]]$coef.i
      }
    }
  }
  cv <- criterion(y, yhat)
  cv.full <- criterion(y,
                       do.call(predict,
                               if (is.null(clusterVariables)) {
                                 predict.cases.args
                               } else {
                                 predict.clusters.args
                               }))

  if (missing(confint))
    confint <- length(y) >= 400
  loss <- getLossFn(cv) # casewise loss function
  if (!is.null(loss)) {
    adj.cv <- cv + cv.full -
      weighted.mean(sapply(result, function(x)
        x$crit.all.i), folds$folds)
    se.cv <- sd(loss(y, yhat)) / sqrt(length(y))
    halfwidth <- qnorm(1 - (1 - level) / 2) * se.cv
    ci <-
      if (confint)
        c(
          lower = adj.cv - halfwidth,
          upper = adj.cv + halfwidth,
          level = round(level * 100)
        )
    else
      NULL
  } else {
    adj.cv <- NULL
    ci <- NULL
  }

  result <- list(
    "CV crit" = cv,
    "adj CV crit" = adj.cv,
    "full crit" = cv.full,
    "confint" = ci,
    "SE adj CV crit" = se.cv,
    "k" = if (k == n)
      "n"
    else
      k,
    "seed" = seed,
    "criterion" = criterion.name,
    "coefficients" = if (details)  fixed.effects(model) else NULL,
    clusters = clusterVariables,
    "n clusters" = if (!is.null(clusterVariables))
      n
    else
      NULL,
    "details" = list(criterion = crit.i,
                     coefficients = coef.i)
  )
  class(result) <- "cv"
  if (reps == 1L) {
    return(result)
  } else {
    res <- cv(
      model = model,
      data = data,
      criterion = criterion,
      k = k,
      ncores = ncores,
      reps = reps - 1L,
      clusterVariables = clusterVariables,
      ...
    )
    if (reps  > 2L) {
      res[[length(res) + 1L]] <- result
    } else {
      res <- list(res, result)
    }
    for (i_ in 1L:(length(res) - 1L)) {
      res[[i_]]["criterion"] <- res[[length(res)]]["criterion"]
    }
    class(res) <- "cvList"
    return(res)
  }
}

#' @describeIn cvCompute used internally by \code{cv()} methods for
#' cross-validating a model-selection procedure; may also be called
#' directly for this purpose, but use via \code{cv()} is preferred.
#' \code{cvSelect()} is exported primarily to support new model-selection procedures.
#' @export
cvSelect <- function(procedure,
                     data,
                     criterion = mse,
                     criterion.name,
                     model,
                     y.expression,
                     k = 10L,
                     confint = n >= 400,
                     level = 0.95,
                     reps = 1L,
                     save.coef,
                     details = k <= 10L,
                     save.model = FALSE,
                     seed,
                     ncores = 1L,
                     ...) {
  if (missing(criterion.name) ||
      is.null(criterion.name))
    criterion.name <- deparse(substitute(criterion))
  selectModelListP <- isTRUE(all.equal(procedure, selectModelList))
  if (!missing(save.coef))
    details <- save.coef

  se.cv <- NA

  n <- nrow(data)
  y <- if (!missing(model)) {
    GetResponse(model)
  } else {
    eval(y.expression, envir = data)
  }
  if (missing(model))
    model <- NULL
  k.save <- k
  if (is.character(k)) {
    if (k == "n" || k == "loo") {
      k <- n
    }
  }
  if (!is.numeric(k) ||
      length(k) > 1L || k > n || k < 2L || k != round(k)) {
    stop('k must be an integer between 2 and n or "n" or "loo"')
  }
  if (k != n) {
    if (missing(seed) || is.null(seed))
      seed <- sample(1e6, 1L)
    set.seed(seed)
    message("R RNG seed set to ", seed)
  } else {
    if (reps > 1L)
      stop("reps should not be > 1 for n-fold CV")
    if (k == n) {
      if (reps > 1L)
        stop("reps should not be > 1 for n-fold CV")
      if (!missing(seed) &&
          !is.null(seed) &&
          !isFALSE(seed))
        message("Note: seed ignored for n-fold CV")
      seed <- NULL
    }
    seed <- NULL
  }
  folds <- folds(n, k)
  yhat <- if (is.factor(y)) {
    factor(rep(NA, n), levels = levels(y))
  } else if (is.character(y)) {
    character(n)
  } else {
    numeric(n)
  }
  crit.all.i <- numeric(k)

  if (details) {
    crit.i <- numeric(k)
    coef.i <- vector(k, mode = "list")
    model.name.i <- character(k)
    names(crit.i) <- names(coef.i) <- names(model.name.i) <-
      paste("fold", 1L:k, sep = ".")
  } else {
    crit.i <- NULL
    coef.i <- NULL
    model.name.i <- NULL
  }

  if (ncores > 1L) {
    cl <- makeCluster(ncores)
    registerDoParallel(cl)
    arglist <- c(
      list(
        data = data,
        indices = 1L,
        details = k <= 10L,
        criterion = criterion,
        model = model
      ),
      list(...)
    )
    if (selectModelListP)
      arglist <- c(arglist, list(k = k.save))
    selection <- foreach(i_ = 1L:k) %dopar% {
      # the following deals with a scoping issue that can
      #   occur with args passed via ...
      arglist$indices <- fold(folds, i_)
      do.call(procedure, arglist)
    }
    stopCluster(cl)

    for (i_ in 1L:k) {
      yhat[fold(folds, i_)] <- selection[[i_]]$fit.i
      crit.all.i[i_] <- selection[[i_]]$crit.all.i

      if (details) {
        crit.i[i_] <- criterion(y[fold(folds, i_)],
                               yhat[fold(folds, i_)])
        coef.i[[i_]] <- selection[[i_]]$coefficients
        model.name.i[[i_]] <-
          if (!is.null(selection[[i_]]$model.name))
            selection[[i_]]$model.name
        else
          ""
      }

    }

  } else {
    for (i_ in 1L:k) {
      indices.i <- fold(folds, i_)
      selection <- if (selectModelListP) {
        procedure(
          data,
          indices.i,
          details = k <= 10L,
          criterion = criterion,
          model = model,
          k = k.save,
          ...
        )
      } else {
        procedure(
          data,
          indices.i,
          details = k <= 10L,
          criterion = criterion,
          model = model,
          ...
        )
      }
      crit.all.i[i_] <- selection$crit.all.i
      yhat[indices.i] <- selection$fit.i

      if (details) {
        crit.i[i_] <- criterion(y[fold(folds, i_)],
                               yhat[fold(folds, i_)])
        coef.i[[i_]] <- selection$coefficients
        model.name.i[[i_]] <-
          if (!is.null(selection$model.name))
            selection$model.name
        else
          ""
      }

    }
  }
  cv <- criterion(y, yhat)
  result.full <- if (selectModelListP) {
    procedure(
      data,
      model = model,
      criterion = criterion,
      #   seed = seed, # to use same folds if necessary
      save.model = save.model,
      k = k.save,
      ...
    )
  } else {
    procedure(
      data,
      model = model,
      criterion = criterion,
      seed = seed,
      # to use same folds if necessary
      save.model = save.model,
      ...
    )
  }
  if (is.list(result.full)) {
    cv.full <- result.full$criterion
    selected.model <- result.full$model
    coef.full <- coef(result.full$model)
    if (!is.null(result.full$model$additional.coefficients)){
      coef.full <- c(coef.full,
                     result.full$model$additional.coefficients)
    }
  } else {
    cv.full <- result.full
    selected.model <- NULL
    coef.full <- NULL
  }

  loss <- getLossFn(cv) # casewise loss function
  if (!is.null(loss)) {
    adj.cv <- cv + cv.full - weighted.mean(crit.all.i, folds$folds)
    se.cv <- sd(loss(y, yhat)) / sqrt(n)
    halfwidth <- qnorm(1 - (1 - level) / 2) * se.cv
    ci <-
      if (confint)
        c(
          lower = adj.cv - halfwidth,
          upper = adj.cv + halfwidth,
          level = round(level * 100)
        )
    else
      NULL
  } else {
    adj.cv <- NULL
    ci <- NULL
  }

  result <-
    list(
      "CV crit" = cv,
      "adj CV crit" = adj.cv,
      "full crit" = cv.full,
      "criterion" = criterion.name,
      "confint" = ci,
      "SE adj CV crit" = se.cv,
      "k" = if (k == n)
        "n"
      else
        k,
      "seed" = seed,
      "coefficients" = if (details) coef.full else NULL,
      "details" = list(
        criterion = crit.i,
        coefficients = coef.i,
        model.name = model.name.i
      ),
      "selected.model" = selected.model
    )
  class(result) <- c("cvSelect", "cv")
  if (reps == 1L) {
    return(result)
  } else {
    if (missing(y.expression))
      y.expression <- NULL
    res <- cvSelect(
      procedure = procedure,
      data = data,
      criterion = criterion,
      criterion.name = criterion.name,
      model = model,
      y.expression = y.expression,
      k = k,
      confint = confint,
      level = level,
      reps = reps - 1L,
      save.coef = save.coef,
      details = details,
      save.model = save.model,
      ncores = ncores,
      ...
    )

    if (reps  > 2L) {
      res[[length(res) + 1L]] <- result
    } else {
      res <- list(res, result)
    }
    class(res) <- c("cvSelectList", "cvList")
    return(res)
  }
}

#' @describeIn cvCompute used internally by \code{cv()} methods (not for direct use).
#' @export
folds <- function(n, k) {
  nk <-  n %/% k # number of cases in each fold
  rem <- n %% k  # remainder
  folds <-
    rep(nk, k) + c(rep(1L, rem), rep(0L, k - rem)) # allocate remainder
  ends <- cumsum(folds) # end of each fold
  starts <- c(1L, ends + 1L)[-(k + 1L)] # start of each fold
  indices <- if (n > k)
    sample(n, n)
  else
    1L:n # permute cases
  result <- list(
    n = n,
    k = k,
    folds = folds,
    starts = starts,
    ends = ends,
    indices = indices
  )
  class(result) <- "folds"
  result
}

#' @describeIn cvCompute to extract a fold from a \code{"folds"} object.
#' @export
fold <- function(folds, i_, ...)
  UseMethod("fold")

#' @describeIn cvCompute \code{fold()} method for \code{"folds"} objects.
#' @export
fold.folds <-
  function(folds, i_, ...)
    folds$indices[folds$starts[i_]:folds$ends[i_]]

#' @describeIn cvCompute \code{print()} method for \code{"folds"} objects.
#' @export
print.folds <- function(x, ...) {
  if (x$k == x$n) {
    cat("LOO:", x$k, "folds for", x$n, "cases")
    return(invisible(x))
  }
  cat(x$k, "folds of approximately", floor(x$n / x$k),
      "cases each")
  for (i_ in 1L:min(x$k, 10L)) {
    cat("\n fold", paste0(i_, ": "))
    fld <- fold(x, i_)
    if (length(fld) <= 10L)
      cat(fld)
    else
      cat(fld[1L:10L], "...")
  }
  if (x$k > 10L)
    cat("\n ...")
  cat("\n")
  invisible(x)
}

#' @export
#' @describeIn cvCompute function to return the response variable
#' from a regression model.
GetResponse <- function(model, ...) {
  UseMethod("GetResponse")
}

#' @describeIn cvCompute default method.
#' @export
GetResponse.default <- function(model, ...) {
  y <- if (!isS4(model))
    model$y
  else
    insight::get_response(model)
  if (is.null(y))
    y <- model.response(model.frame(model))
  if (!is.vector(y))
    stop("non-vector response")
  if (!is.numeric(y))
    stop("non-numeric response")
  y
}

#' @describeIn cvCompute \code{"merMod"} method.
#' @export
GetResponse.merMod <- function(model, ...) {
  y <- insight::get_response(model)
  if (is.factor(y)) {
    levels <- levels(y)
    failure <- levels[1L]
    if (length(levels) > 2L) {
      message(
        "Note: the response has more than 2 levels.\n",
        " The first level ('",
        failure,
        "') denotes failure (0),\n",
        " the others success (1)"
      )
    }
    y <- as.numeric(y != failure)
  }
  if (!is.vector(y))
    stop("non-vector response")
  if (!is.numeric(y))
    stop("non-numeric response")
  y
}

#' @describeIn cvCompute \code{"lme"} method.
#' @export
GetResponse.lme <- function(model, ...)
  insight::get_response(model)

#' @describeIn cvCompute \code{"glmmTMB"} method.
#' @export
GetResponse.glmmTMB <- function (model, ...){
  y <- insight::get_response(model)
  if (length(dim(y)) == 2 && dim(y)[2] == 1) y <- y[, 1]
  if (!is.vector(y))
    stop("non-vector response")
  if (!is.numeric(y))
    stop("non-numeric response")
  y
}

#' @describeIn cvCompute \code{"modList"} method.
#' @export
GetResponse.modList <- function(model, ...)
  GetResponse(model[[1L]])

#' @describeIn cvCompute check a model formula to determine whether it include
#' variables not in the data to which the model was fit; prints a warning if this
#' is not the case.
#' @param data.names names of variables in the data set to which the model was
#' fit; if missing, an attempt will be made to extract the data from the model.
#' @export
checkFormula <-  function(model, data.names){
  if (missing(data.names)) {
    data.names <- colnames(insight::get_data(model))
  }
  f <- insight::find_formula(model)
  if (is.null(f)) return(NA)
  warn <- FALSE
  for (i in seq_along(f)){
    f.names <- all.vars(f[[i]])
    extra <- setdiff(f.names, data.names)
    if (length(extra) > 0) {
      warning(paste0("the following variable",
                     if (length(extra) > 1) "s are " else " is ",
                     "\nin the model formula but not in the data set:\n ",
                     paste(extra, collapse=", "),
                     "\nexpect errors or incorrect results"))
      warn <- TRUE
    }
  }
  return(!warn)
}



# not exported

summarizeReps <- function(x) {
  CVcrit <- mean(sapply(x, function(x)
    x[["CV crit"]]))
  CVcritSD <- sd(sapply(x, function(x)
    x[["CV crit"]]))
  CVcritRange <- range(sapply(x, function(x)
    x[["CV crit"]]))
  if (!is.null(x[[1L]][["adj CV crit"]])) {
    adjCVcrit <- mean(sapply(x, function(x)
      x[["adj CV crit"]]))
    adjCVcritSD <- sd(sapply(x, function(x)
      x[["adj CV crit"]]))
    adjCVcritRange <-
      range(sapply(x, function(x)
        x[["adj CV crit"]]))
  } else {
    adjCVcrit <- adjCVcritSD <- adjCVcritRange <- NULL
  }
  list(
    "CV crit" = CVcrit,
    "adj CV crit" = adjCVcrit,
    "CV crit range" = CVcritRange,
    "SD CV crit" = CVcritSD,
    "SD adj CV crit" = adjCVcritSD,
    "adj CV crit range" = adjCVcritRange
  )
}

getLossFn <- function(cv) {
  fn.body <- attr(cv, "casewise loss")
  if (is.null(fn.body))
    return(NULL)
  eval(parse(text = paste0(
    "function(y, yhat) {\n",
    paste(fn.body, collapse = "\n"),
    "\n}"
  )))
}

Merge <- function(...) {
  Ds <- lapply(list(...), as.data.frame, optional=TRUE)
  names <- unique(unlist(lapply(Ds, colnames)))
  for (i_ in 1L:length(Ds)) {
    missing <- setdiff(names, colnames(Ds[[i_]]))
    Ds[[i_]][, missing] <- NA
  }
  do.call("rbind", Ds)
}


utils::globalVariables(c("b", "y", "dots"))
