library(bigsnpr)

chr6 <- snp_attach("../Dubois2010_data/celiac_chr6.rds")
G <- chr6$genotypes$copy(code = c(0, 1, 2, 0, rep(NA, 252)))
dim(G)
big_counts(G, ind.col = 1:10)
CHR <- chr6$map$chromosome
POS <- chr6$map$physical.pos
stats <- big_scale()(G)

POS2 <- snp_asGeneticPos(CHR, POS, dir = "tmp-data/")
plot(POS, POS2, pch = 20)

corr <- runonce::save_run(
  snp_cor(chr6$genotypes, infos.pos = POS2, size = 3 / 1000, ncores = 6),
  file = "tmp-data/corr_chr6.rds"
)
# Matrix::rankMatrix(corr, method = "qr")
# 18937  (out of 18941)

hist(log10(abs(corr@x)))

corr2 <- as_SFBM(corr)


set.seed(1)
# Simu phenotype
ind <- sample(ncol(G), ncol(G) * 10^-runif(1, 0.5, 2.5))
h2_1 <- 0.2
h2_2 <- 0.3
rho <- -0.4
rho_to_cov <- rho * sqrt(h2_1 * h2_2)
(cov <- matrix(c(h2_1, rho_to_cov, rho_to_cov, h2_2), 2))
beta <- MASS::mvrnorm(length(ind), rep(0, 2), cov / length(ind))

g <- big_prodMat(G, beta, ind.col = ind,
                 center = stats$center[ind],
                 scale = stats$scale[ind])
cov(g)

rhoE <- 0
rhoE_to_cov <- rhoE * sqrt((1 - h2_1) * (1 - h2_2))
covE <- matrix(c(1 - h2_1, rhoE_to_cov, rhoE_to_cov, 1 - h2_2), 2)
e <- MASS::mvrnorm(nrow(G), rep(0, 2), covE)
cov(y <- g + e)

# GWAS
ind.gwas <- sample(nrow(G), 8e3)
gwas <- big_univLinReg(G, y[ind.gwas, 1], ind.train = ind.gwas)
plot(gwas, type = "Manhattan")
hist(lpval <- -predict(gwas))

ind.val <- setdiff(rows_along(G), ind.gwas)

# LDSc reg
df_beta <- data.frame(beta = gwas$estim, beta_se = gwas$std.err,
                      n_eff = length(ind.gwas))
(ldsc <- snp_ldsc2(corr, df_beta))
ldsc_h2_est <- ldsc[["h2"]]


# LDpred2-auto
auto <- snp_ldpred2_auto(corr2, df_beta, h2_init = ldsc_h2_est,
                         burn_in = 300, num_iter = 200, report_step = 10,
                         verbose = FALSE)

pred <- big_prodVec(G, auto[[1]]$beta_est, ind.row = ind.val)
cor(pred, y[ind.val, 1]) ** 2
dim(bsamp <- auto[[1]]$sample_beta)
Rb <- apply(bsamp, 2, function(x) bigsparser::sp_prodVec(corr2, x))
covsamp <- crossprod(bsamp, Rb)
round(100 * covsamp, 1)[1:5, 1:5]


## Second phenotype
gwas2 <- big_univLinReg(G, y[ind.gwas, 2], ind.train = ind.gwas)
df_beta2 <- data.frame(beta = gwas2$estim, beta_se = gwas2$std.err,
                       n_eff = length(ind.gwas))
(ldsc_h2_est2 <- snp_ldsc2(corr, df_beta2)[["h2"]])
auto2 <- snp_ldpred2_auto(corr2, df_beta2, h2_init = ldsc_h2_est2,
                          burn_in = 300, num_iter = 200, report_step = 10,
                          verbose = FALSE)

pred2 <- big_prodVec(G, auto2[[1]]$beta_est, ind.row = ind.val)
cor(pred2, y[ind.val, 2]) ** 2
dim(bsamp2 <- auto2[[1]]$sample_beta)
covsamp2 <- crossprod(bsamp2, apply(bsamp2, 2, function(x)
  bigsparser::sp_prodVec(corr2, x)))
round(100 * covsamp2, 1)[1:5, 1:5]

covsamp3 <- crossprod(bsamp2, Rb)
r2_1 <- median(covsamp[upper.tri(covsamp)])
r2_2 <- median(covsamp2[upper.tri(covsamp2)])
signed_sqrt <- function(x) sign(x) * sqrt(abs(x))
quantile(signed_sqrt(covsamp3 / sqrt(r2_1 * r2_2)), c(0.025, 0.5, 0.975))
quantile(signed_sqrt(covsamp3 / sqrt(r2_1 * r2_2)) *
           sqrt(diag(covsamp2) %o% diag(covsamp)), c(0.025, 0.5, 0.975))
c(cor(g)[1, 2], cov(g)[1, 2])

all_rg <- replicate(100, {
  x <- bsamp[, sample(ncol(bsamp), 1)]
  y <- bsamp2[, sample(ncol(bsamp2), 1)]
  Rx <- bigsparser::sp_prodVec(corr2, x)
  Ry <- bigsparser::sp_prodVec(corr2, y)
  crossprod(x, Ry) / sqrt(crossprod(x, Rx) * crossprod(y, Ry))
})
hist(all_rg)

x_marg <- with(df_beta, beta / sqrt(n_eff * beta_se^2 + beta^2))
y_marg <- with(df_beta2, beta / sqrt(n_eff * beta_se^2 + beta^2))
all_rg2 <- replicate(100, {
  x <- bsamp[, sample(ncol(bsamp), 1)]
  y <- bsamp2[, sample(ncol(bsamp2), 1)]
  (crossprod(x, y_marg) + crossprod(y, x_marg)) / 2 /
    sqrt(crossprod(x, x_marg) * crossprod(y, y_marg))
})
hist(all_rg2)

r2_1 <- colMeans(covsamp)
r2_2 <- colMeans(covsamp2)
quantile(signed_sqrt(covsamp3 / sqrt(r2_2 %o% r2_1)), c(0.025, 0.5, 0.975))
quantile(est <- signed_sqrt(covsamp3 / sqrt(r2_2 %o% r2_1)) *
           sqrt(diag(covsamp2) %o% diag(covsamp)), c(0.025, 0.5, 0.975))
c(cor(g)[1, 2], cov(g)[1, 2])
# cov(g)

coef <- ncol(corr) / length(ind.gwas)
quantile((est - cor(y)[1, 2] * coef) / (1 - coef), c(0.025, 0.5, 0.975))

cov(y)
rho_to_cov
rhoE_to_cov
