#' Data Depths
#'
#' `step_depth` creates a *specification* of a recipe
#'  step that will convert numeric data into measurement of
#'  *data depth*. This is done for each value of a categorical
#'  class variable.
#'
#' @inheritParams step_pca
#' @inheritParams step_center
#' @param class A single character string that specifies a single
#'  categorical variable to be used as the class.
#' @param metric A character string specifying the depth metric.
#'  Possible values are "potential", "halfspace", "Mahalanobis",
#'  "simplicialVolume", "spatial", and "zonoid".
#' @param options A list of options to pass to the underlying
#'  depth functions. See [ddalpha::depth.halfspace()],
#'  [ddalpha::depth.Mahalanobis()],
#'  [ddalpha::depth.potential()],
#'  [ddalpha::depth.projection()],
#'  [ddalpha::depth.simplicial()],
#'  [ddalpha::depth.simplicialVolume()],
#'  [ddalpha::depth.spatial()],
#'  [ddalpha::depth.zonoid()].
#' @param data The training data are stored here once after
#'  [prep()] is executed.
#' @template step-return
#' @family multivariate transformation steps
#' @export
#' @details Data depth metrics attempt to measure how close data a
#'  data point is to the center of its distribution. There are a
#'  number of methods for calculating depth but a simple example is
#'  the inverse of the distance of a data point to the centroid of
#'  the distribution. Generally, small values indicate that a data
#'  point not close to the centroid. `step_depth` can compute a
#'  class-specific depth for a new data point based on the proximity
#'  of the new value to the training set distribution.
#'
#' This step requires the \pkg{ddalpha} package. If not installed, the
#'  step will stop with a note about installing the package.
#'
#' Note that the entire training set is saved to compute future
#'  depth values. The saved data have been trained (i.e. prepared)
#'  and baked (i.e. processed) up to the point before the location
#'  that `step_depth` occupies in the recipe. Also, the data
#'  requirements for the different step methods may vary. For
#'  example, using `metric = "Mahalanobis"` requires that each
#'  class should have at least as many rows as variables listed in
#'  the `terms` argument.
#'
#'  The function will create a new column for every unique value of
#'  the `class` variable. The resulting variables will not
#'  replace the original values and by default have the prefix `depth_`. The
#'  naming format can be changed using the `prefix` argument.
#'
#'  # Tidying
#'
#'  When you [`tidy()`][tidy.recipe()] this step, a tibble with columns
#'  `terms` (the selectors or variables selected) and `class` is returned.
#'
#' @template case-weights-not-supported
#'
#' @examplesIf rlang::is_installed("ddalpha")
#'
#' # halfspace depth is the default
#' rec <- recipe(Species ~ ., data = iris) %>%
#'   step_depth(all_numeric_predictors(), class = "Species")
#'
#' # use zonoid metric instead
#' # also, define naming convention for new columns
#' rec <- recipe(Species ~ ., data = iris) %>%
#'   step_depth(all_numeric_predictors(),
#'     class = "Species",
#'     metric = "zonoid", prefix = "zonoid_"
#'   )
#'
#' rec_dists <- prep(rec, training = iris)
#'
#' dists_to_species <- bake(rec_dists, new_data = iris)
#' dists_to_species
#'
#' tidy(rec, number = 1)
#' tidy(rec_dists, number = 1)
step_depth <-
  function(recipe,
           ...,
           class,
           role = "predictor",
           trained = FALSE,
           metric = "halfspace",
           options = list(),
           data = NULL,
           prefix = "depth_",
           skip = FALSE,
           id = rand_id("depth")) {
    if (!is.character(class) || length(class) != 1) {
      rlang::abort("`class` should be a single character value.")
    }

    recipes_pkg_check(required_pkgs.step_depth())

    add_step(
      recipe,
      step_depth_new(
        terms = enquos(...),
        class = class,
        role = role,
        trained = trained,
        metric = metric,
        options = options,
        data = data,
        prefix = prefix,
        skip = skip,
        id = id
      )
    )
  }

step_depth_new <-
  function(terms, class, role, trained, metric,
           options, data, prefix, skip, id) {
    step(
      subclass = "depth",
      terms = terms,
      class = class,
      role = role,
      trained = trained,
      metric = metric,
      options = options,
      data = data,
      prefix = prefix,
      skip = skip,
      id = id
    )
  }

#' @export
prep.step_depth <- function(x, training, info = NULL, ...) {
  class_var <- x$class[1]
  x_names <- recipes_eval_select(x$terms, training, info)
  check_type(training[, x_names])

  x_dat <-
    split(training[, x_names], getElement(training, class_var))
  x_dat <- lapply(x_dat, as.matrix)
  step_depth_new(
    terms = x$terms,
    class = x$class,
    role = x$role,
    trained = TRUE,
    metric = x$metric,
    options = x$options,
    data = x_dat,
    prefix = x$prefix,
    skip = x$skip,
    id = x$id
  )
}

get_depth <- function(tr_dat, new_dat, metric, opts) {
  if (ncol(new_dat) == 0L) {
    # ddalpha can't handle 0 col inputs
    return(rep(NA_real_, nrow(new_dat)))
  }

  if (!is.matrix(new_dat)) {
    new_dat <- as.matrix(new_dat)
  }
  opts$data <- tr_dat
  opts$x <- new_dat
  dd_call <- call2(paste0("depth.", metric), !!!opts, .ns = "ddalpha")
  eval(dd_call)
}

#' @export
bake.step_depth <- function(object, new_data, ...) {
  x_names <- colnames(object$data[[1]])
  check_new_data(x_names, object, new_data)

  x_data <- as.matrix(new_data[, x_names])
  res <- lapply(
    object$data,
    get_depth,
    new_dat = x_data,
    metric = object$metric,
    opts = object$options
  )
  res <- as_tibble(res)
  newname <- paste0(object$prefix, colnames(res))
  res <- check_name(res, new_data, object, newname)
  res <- bind_cols(new_data, res)
  res
}

print.step_depth <-
  function(x, width = max(20, options()$width - 30), ...) {
    title <- glue::glue("Data depth by {x$class} for ")

    if (x$trained) {
      x_names <- colnames(x$data[[1]])
    } else {
      x_names <- character()
    }

    print_step(x_names, x$terms, x$trained, title, width)
    invisible(x)
  }



#' @rdname tidy.recipe
#' @export
tidy.step_depth <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble(
      terms = colnames(x$data[[1]]) %||% character(),
      class = x$class
    )
  } else {
    term_names <- sel2char(x$terms)
    res <- tibble(
      terms = term_names,
      class = na_chr
    )
  }
  res$id <- x$id
  res
}


#' @rdname required_pkgs.recipe
#' @export
required_pkgs.step_depth <- function(x, ...) {
  c("ddalpha")
}
