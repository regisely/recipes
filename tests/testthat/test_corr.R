library(testthat)
library(recipes)

n <- 100
set.seed(424)
dat <- matrix(rnorm(n * 5), ncol = 5)
dat <- as.data.frame(dat)
dat$duplicate <- dat$V1
dat$V6 <- -dat$V2 + runif(n) * .2

test_that("high filter", {
  set.seed(1)
  rec <- recipe(~., data = dat)
  filtering <- rec %>%
    step_corr(all_predictors(), threshold = .5)

  filtering_trained <- prep(filtering, training = dat, verbose = FALSE)

  removed <- c("V6", "V1")

  expect_equal(filtering_trained$steps[[1]]$removals, removed)
})

test_that("low filter", {
  rec <- recipe(~., data = dat)
  filtering <- rec %>%
    step_corr(all_predictors(), threshold = 1)

  filtering_trained <- prep(filtering, training = dat, verbose = FALSE)

  expect_equal(filtering_trained$steps[[1]]$removals, numeric(0))
})

test_that("many missing values", {
  dat2 <- dat
  dat2$V4 <- NA_real_
  rec <- recipe(~., data = dat2)
  filtering <- rec %>%
    step_corr(all_predictors(), threshold = .25)

  expect_snapshot(
    filtering_trained <- prep(filtering, training = dat2, verbose = FALSE)
  )

  expect_equal(filtering_trained$steps[[1]]$removals, paste0("V", 1:2))
})

test_that("occasional missing values", {
  dat3 <- dat
  dat3$V1[1] <- NA_real_
  dat3$V4[10] <- NA_real_
  rec <- recipe(~., data = dat3)
  filtering <- rec %>%
    step_corr(all_predictors(), threshold = .25, use = "everything")

  expect_snapshot(
    filtering_trained <- prep(filtering, training = dat3, verbose = FALSE)
  )

  expect_equal(filtering_trained$steps[[1]]$removals, "V2")
})


test_that("printing", {
  set.seed(1)
  rec <- recipe(~., data = dat)
  filtering <- rec %>%
    step_corr(all_predictors(), threshold = .5)
  expect_snapshot(print(filtering))
  expect_snapshot(prep(filtering))
})


test_that("tunable", {
  rec <-
    recipe(~., data = iris) %>%
    step_corr(all_predictors())
  rec_param <- tunable.step_corr(rec$steps[[1]])
  expect_equal(rec_param$name, c("threshold"))
  expect_true(all(rec_param$source == "recipe"))
  expect_true(is.list(rec_param$call_info))
  expect_equal(nrow(rec_param), 1)
  expect_equal(
    names(rec_param),
    c("name", "call_info", "source", "component", "component_id")
  )
})

test_that("empty selection prep/bake is a no-op", {
  rec1 <- recipe(mpg ~ ., mtcars)
  rec2 <- step_corr(rec1)

  rec1 <- prep(rec1, mtcars)
  rec2 <- prep(rec2, mtcars)

  baked1 <- bake(rec1, mtcars)
  baked2 <- bake(rec2, mtcars)

  expect_identical(baked1, baked2)
})

test_that("empty selection tidy method works", {
  rec <- recipe(mpg ~ ., mtcars)
  rec <- step_corr(rec)

  expect_identical(
    tidy(rec, number = 1),
    tibble(terms = character(), id = character())
  )

  rec <- prep(rec, mtcars)

  expect_identical(
    tidy(rec, number = 1),
    tibble(terms = character(), id = character())
  )
})

test_that("empty printing", {
  skip_if(packageVersion("rlang") < "1.0.0")
  rec <- recipe(mpg ~ ., mtcars)
  rec <- step_corr(rec)

  expect_snapshot(rec)

  rec <- prep(rec, mtcars)

  expect_snapshot(rec)
})

test_that("case weights", {
  dat_caseweights <- dat %>%
    mutate(V3_dup = V3 + rep(c(0, 1), c(50, 50)),
           wts = rep(c(1, 2), c(50, 50)),
           wts = frequency_weights(wts))

  # low filter
  filtering <- recipe(~., data = dat_caseweights) %>%
    step_corr(all_predictors(), threshold = 0.92)

  filtering_trained <- prep(filtering)

  removed <- c("V1", "V2")

  expect_equal(filtering_trained$steps[[1]]$removals, removed)

  # high filter
  filtering <- recipe(~., data = dat_caseweights) %>%
    step_corr(all_predictors(), threshold = 0.9)

  filtering_trained <- prep(filtering)

  removed <- c("V3_dup", "V1", "V2")

  expect_equal(filtering_trained$steps[[1]]$removals, removed)

  expect_snapshot(filtering_trained)

  # ----------------------------------------------------------------------------
  dat_caseweights <- dat %>%
    mutate(V3_dup = V3 + rep(c(0, 1), c(50, 50)),
           wts = rep(c(1, 2), c(50, 50)),
           wts = importance_weights(wts))

  # low filter
  filtering <- recipe(~., data = dat_caseweights) %>%
    step_corr(all_predictors(), threshold = 0.92)

  filtering_trained <- prep(filtering)

  removed <- c("V6", "V1")

  expect_equal(filtering_trained$steps[[1]]$removals, removed)

  # high filter
  filtering <- recipe(~., data = dat_caseweights) %>%
    step_corr(all_predictors(), threshold = 0.9)

  filtering_trained <- prep(filtering)

  removed <- c("V6", "V1", "V3")

  expect_equal(filtering_trained$steps[[1]]$removals, removed)

  expect_snapshot(filtering_trained)
})
