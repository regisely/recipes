#' Assign missing categories to "unknown"
#'
#' `step_unknown` creates a *specification* of a recipe
#'  step that will assign a missing value in a factor level to"unknown".
#'
#' @inheritParams step_center
#' @param new_level A single character value that will be assigned
#'  to new factor levels.
#' @param objects A list of objects that contain the information
#'  on factor levels that will be determined by [prep()].
#' @template step-return
#' @family dummy variable and encoding steps
#' @seealso [dummy_names()]
#' @export
#' @details The selected variables are adjusted to have a new
#'  level (given by `new_level`) that is placed in the last
#'  position.
#'
#' Note that if the original columns are character, they will be
#'  converted to factors by this step.
#'
#' If `new_level` is already in the data given to `prep`, an error
#'  is thrown.
#'
#' # Tidying
#'
#' When you [`tidy()`][tidy.recipe()] this step, a tibble with columns
#' `terms` (the columns that will be affected) and `value` (the factor
#'  levels that is used for the new value) is returned.
#'
#' @template case-weights-not-supported
#'
#' @examplesIf rlang::is_installed("modeldata")
#' data(Sacramento, package = "modeldata")
#'
#' rec <-
#'   recipe(~ city + zip, data = Sacramento) %>%
#'   step_unknown(city, new_level = "unknown city") %>%
#'   step_unknown(zip, new_level = "unknown zip") %>%
#'   prep()
#'
#' table(bake(rec, new_data = NULL) %>% pull(city),
#'   Sacramento %>% pull(city),
#'   useNA = "always"
#' ) %>%
#'   as.data.frame() %>%
#'   dplyr::filter(Freq > 0)
#'
#' tidy(rec, number = 1)
step_unknown <-
  function(recipe,
           ...,
           role = NA,
           trained = FALSE,
           new_level = "unknown",
           objects = NULL,
           skip = FALSE,
           id = rand_id("unknown")) {
    add_step(
      recipe,
      step_unknown_new(
        terms = enquos(...),
        role = role,
        trained = trained,
        new_level = new_level,
        objects = objects,
        skip = skip,
        id = id
      )
    )
  }

step_unknown_new <-
  function(terms, role, trained, new_level, objects, skip, id) {
    step(
      subclass = "unknown",
      terms = terms,
      role = role,
      trained = trained,
      new_level = new_level,
      objects = objects,
      skip = skip,
      id = id
    )
  }

#' @export
prep.step_unknown <- function(x, training, info = NULL, ...) {
  col_names <- recipes_eval_select(x$terms, training, info)
  col_check <- dplyr::filter(info, variable %in% col_names)
  if (any(col_check$type != "nominal")) {
    rlang::abort(
      paste0(
        "Columns must be character or factor: ",
        paste0(col_check$variable[col_check$type != "nominal"],
          collapse = ", "
        )
      )
    )
  }

  # Get existing levels and their factor type (i.e. ordered)
  objects <- lapply(training[, col_names], get_existing_values)
  # Check to make sure that there are not duplicate levels
  level_check <-
    map_lgl(objects, function(x, y) y %in% x, y = x$new_level)
  if (any(level_check)) {
    rlang::abort(
      paste0(
        "Columns already contain a level '", x$new_level, "': ",
        paste0(names(level_check)[level_check], collapse = ", ")
      )
    )
  }

  step_unknown_new(
    terms = x$terms,
    role = x$role,
    trained = TRUE,
    new_level = x$new_level,
    objects = objects,
    skip = x$skip,
    id = x$id
  )
}

#' @export
bake.step_unknown <- function(object, new_data, ...) {
  check_new_data(names(object$objects), object, new_data)
  for (i in names(object$objects)) {
    new_data[[i]] <-
      ifelse(is.na(new_data[[i]]), object$new_level, as.character(new_data[[i]]))

    new_levels <- c(object$object[[i]], object$new_level)

    if (!all(new_data[[i]] %in% new_levels)) {
      warn_new_levels(
        new_data[[i]],
        new_levels,
        paste0(
          "\nNew levels will be coerced to `NA` by `step_unknown()`.",
          "\nConsider using `step_novel()` before `step_unknown()`."
        )
      )
    }

    new_data[[i]] <-
      factor(new_data[[i]],
        levels = new_levels,
        ordered = attributes(object$object[[i]])$is_ordered
      )
  }
  new_data
}

print.step_unknown <-
  function(x, width = max(20, options()$width - 30), ...) {
    title <- "Unknown factor level assignment for "
    print_step(names(x$objects), x$terms, x$trained, title, width)
    invisible(x)
  }

#' @rdname tidy.recipe
#' @export
tidy.step_unknown <- function(x, ...) {
  if (is_trained(x)) {
    res <- tibble(
      terms = names(x$objects),
      value = rep(x$new_level, length(x$objects))
    )
  } else {
    term_names <- sel2char(x$terms)
    res <- tibble(
      terms = term_names,
      value = rep(x$new_level, length(term_names))
    )
  }
  res$id <- x$id
  res
}
