# This function is taken from the following tutorial:
# https://tm4ss.github.io/docs/Tutorial_5_Co-occurrence.html

calculate_cooc_stats <- function(cooc_term, dtm, measure = "DICE") {

  # Ensure Matrix (SparseM} or matrix {base} format
  require(Matrix)
  require(slam)
  if (is.simple_triplet_matrix(dtm)) {
    dtm <- sparseMatrix(i = dtm$i, j = dtm$j, x = dtm$v, dims = c(dtm$nrow, dtm$ncol), dimnames = dimnames(dtm))
  }

  # Ensure binary DTM
  if (any(dtm > 1)) {
    dtm[dtm > 1] <- 1
  }

  # calculate cooccurrence counts
  coocCounts <- t(dtm) %*% dtm

  # retrieve numbers for statistic calculation
  k <- nrow(dtm)
  ki <- sum(dtm[, cooc_term])
  kj <- colSums(dtm)
  names(kj) <- colnames(dtm)
  kij <- coocCounts[cooc_term, ]

  # calculate statistics
  switch(measure,
    DICE = {
      dicesig <- 2 * kij / (ki + kj)
      dicesig <- dicesig[order(dicesig, decreasing = TRUE)]
      sig <- dicesig
    },
    LOGLIK = {
      logsig <- 2 * ((k * log(k)) - (ki * log(ki)) - (kj * log(kj)) + (kij * log(kij))
        + (k - ki - kj + kij) * log(k - ki - kj + kij)
        + (ki - kij) * log(ki - kij) + (kj - kij) * log(kj - kij)
        - (k - ki) * log(k - ki) - (k - kj) * log(k - kj))
      logsig <- logsig[order(logsig, decreasing = T)]
      sig <- logsig
    },
    MI = {
      mutualInformationSig <- log(k * kij / (ki * kj))
      mutualInformationSig <- mutualInformationSig[order(mutualInformationSig, decreasing = TRUE)]
      sig <- mutualInformationSig
    },
    {
      sig <- sort(kij, decreasing = TRUE)
    }
  )
  sig <- sig[-match(cooc_term, names(sig))]
  return(sig)
}
