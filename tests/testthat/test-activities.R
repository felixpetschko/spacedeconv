activity_spe <- function() {
  withr::local_seed(89)
  x <- matrix(rpois(200 * 8, 5), 200, 8,
    dimnames = list(paste0("G", 1:200), paste0("spot", c(8, 2, 6, 1, 7, 3, 5, 4))))
  x[1:10, 1:4] <- x[1:10, 1:4] + 20
  x[11:20, 5:8] <- x[11:20, 5:8] + 20
  SpatialExperiment::SpatialExperiment(assays = list(counts = as(x, "dgCMatrix")),
    spatialCoords = cbind(x = 1:8, y = rep(0:1, 4)), sample_id = rep("sample01", 8))
}

activity_network <- function() {
  data.frame(source = rep(c("A", "B"), each = 10), target = paste0("G", 1:20), mor = 1)
}

for (method in c("wsum", "wmean", "aucell", "fgsea", "gsva", "mdt", "mlm", "ora", "udt", "ulm", "viper")) {
  test_that(paste("real activity scoring:", method), {
    local_test_state()
    optional <- c(aucell = "AUCell", fgsea = "fgsea", mdt = "ranger", viper = "viper")
    if (method %in% names(optional)) skip_if_not_installed(optional[[method]])
    spe <- normalize(activity_spe())
    out <- compute_activities(spe, activity_network(), method = method)
    expect_preserved(out, spe)
    expect_true(all(c("collectri_A", "collectri_B") %in% names(colData(out))))
    a <- out$collectri_A
    b <- out$collectri_B
    expect_true(all(is.finite(c(a, b))))
    expect_gt(mean(a[1:4]), mean(a[5:8]))
    expect_gt(mean(b[5:8]), mean(b[1:4]))
  })
}

test_that("activity result insertion aligns conditions by ID", {
  spe <- small_spe()
  values <- data.frame(statistic = "ulm", source = "A", condition = rev(colnames(spe)), score = 1:6)
  local_mocked_bindings(run_ulm = function(...) values)
  out <- compute_activities(spe, activity_network(), method = "ulm", assay = "counts")
  expect_equal(out$collectri_A, as.numeric(6:1))
})

test_that("reference retrieval forwards selection and filters confidence", {
  calls <- list()
  local_mocked_bindings(fetch_activity_reference = function(method, organism, ...) {
    calls[[length(calls) + 1L]] <<- c(list(method = method, organism = organism), list(...))
    data.frame(source = c("A", "B"), target = c("G1", "G2"), mor = 1, confidence = c("A", "D"))
  })
  out <- get_decoupleR_reference("dorothea", organism = "mouse", confidence = "A")
  expect_equal(out$source, "A")
  expect_equal(calls[[1]]$organism, "mouse")
  out <- get_decoupleR_reference("progeny", n_genes = 25)
  expect_equal(nrow(out), 2)
  expect_equal(calls[[2]]$top, 25)
  expect_warning(get_decoupleR_reference("collectri", confidence = "A"), "does not use")
  expect_equal(calls[[3]]$method, "collectri")
})
