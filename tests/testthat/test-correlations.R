test_that("spatial correlations report coefficients rather than confidence limits", {
  local_test_device()
  spe <- result_spe()
  spe$quantiseq_C <- c(.1, .5, .2, .8, .3, .7)
  x <- as.matrix(colData(spe)[, available_results(spe, "quantiseq")])
  out <- spatialcorr(spe, "quantiseq")
  expect_equal(out$corr, cor(x), tolerance = 1e-10)
  p <- corrplot::cor.mtest(x)$p
  expect_equal(out$padj[lower.tri(out$padj)], p.adjust(p[lower.tri(p)], "fdr"))
  expect_equal(out$padj, t(out$padj))
  expect_equal(unname(diag(out$padj)),  rep(0, 3))
  expect_error(spatialcorr(spe, "absent"), "does not exist")
  expect_error(spatialcorr(spe, "quantiseq", adjust = "bad"), "Invalid")
})

test_that("expression correlation passes the correct values to its plot", {
  local_test_device()
  sig <- cbind(A = c(1, 4, 2, 8, 5, 3), B = c(6, 2, 4, 1, 3, 5), C = c(2, 3, 6, 4, 1, 8))
  captured <- NULL
  local_mocked_bindings(corrplot = function(corr, ...) { captured <<- corr })
  for (method in c("pearson", "spearman")) {
    corr_expr(sig, cor_method = method)
    expect_equal(captured, cor(sig, method = method))
  }
  corr_expr(sig, log = TRUE)
  expect_equal(captured, cor(log1p(sig)))
  expect_error(corr_expr(sig, cor_method = "bad"), "cor_method")
})
