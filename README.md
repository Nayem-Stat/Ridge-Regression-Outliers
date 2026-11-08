# Ridge Regression with Outliers

**Comparison among Ordinary Least Squares, Ridge, Lasso, and Elastic Net Estimators in the Presence of Outliers: Simulation and Application**

HM Nayem, Sajeda Aziz, B. M. Golam Kibria (2024). *International Journal of Statistical Sciences*, 24(2) (Special), 25-48.

[![DOI](https://img.shields.io/badge/DOI-10.3329%2Fijss.v24i20.78212-blue)](https://doi.org/10.3329/ijss.v24i20.78212)
![R](https://img.shields.io/badge/language-R-276DC3)

---

## Summary

Multicollinearity inflates the variance of the OLS estimator, and outliers in the response make it worse. This paper compares OLS with **23 ridge-parameter (k) estimators**, the **generalized ridge (GR)**, **Lasso** and **Elastic Net (EN)** through an extensive Monte Carlo study, using the **average mean squared error (AMSE)** as the criterion, both with and without outliers. Two classic real data sets (Portland cement and Longley) illustrate the findings.

**Main findings**

- **No outliers, small n, moderate-to-high collinearity (rho around 0.95):** ridge estimators k10, k11, k13 and k15 perform best.
- **With outliers, small n and high error variance:** k7, k16, k22 and k23 perform best.
- **Large samples:** GR, Elastic Net and Lasso give the lowest AMSE.
- All shrinkage estimators clearly beat OLS when collinearity is severe.

## Simulation design

| Factor | Levels |
|---|---|
| Predictors p | 5, 10 |
| Correlation rho | 0.90, 0.95, 0.99 |
| Sample size n | 20, 30, 50, 100 |
| Error variance sigma^2 | 1, 5 |
| Outliers in y | 0%, 10%, 25% |
| Replications N | 5000 |
| True coefficients | beta = (1, ..., 1) |

Predictors are generated as x_ij = sqrt(1 - rho^2) z_ij + rho z_ip (McDonald & Galarneau, 1975; Gibbons, 1981). Outliers are created by adding a N(10, 5^2) shock to a random subset of the responses.

## Estimators

| Paper | Code name | Description / source |
|---|---|---|
| k1 | k27 | Mermi et al. (2024) |
| k2 | k44 | Mermi et al. (2024) |
| k3 | k49 | Mermi et al. (2024) |
| k4 | k133 | Mermi et al. (2024) |
| k5 | k13 | median of sigma^2/beta_i^2 + 1/lambda_i (Kibria, 2023) |
| k6 | k105 | maximum (Kibria, 2023) |
| k7 | k104 | minimum (Kibria, 2023) |
| k8 | k106 | geometric mean (Kibria, 2023) |
| k9 | k107 | harmonic mean (Kibria, 2023) |
| k10 | k243 | Mermi et al. (2024) |
| k11 | k126 | Mermi et al. (2024) |
| k12 | k117 | Mermi et al. (2024) |
| k13 | k231 | Mermi et al. (2024) |
| k14 | k108 | Mermi et al. (2024) |
| k15 | k239 | Mermi et al. (2024) |
| k16 | k211 | Mermi et al. (2024) |
| k17 | k284 | Mermi et al. (2024) |
| k18 | k29 | Mermi et al. (2024) |
| k19 | k190 | Mermi et al. (2024) |
| k20 | k143 | Mermi et al. (2024) |
| k21 | k151 | Mermi et al. (2024) |
| k22 | Kck1 | sigma * p^(1 + p/n) (Kibria & Lukman, 2020) |
| k23 | Kck | sigma * max(p^(1 + p/n), p^(1 + 1/p)) (Kibria & Lukman, 2020) |
| - | OLS, Lasso, ElasticNet, OptimalRidge | `lm`, `cv.glmnet` (alpha = 1, 0.5, 0) |

k1-k4 and k10-k21 are the 16 best of the 366 estimators reviewed by Mermi et al. (2024).

## Selected results

**Figure 3.1** - AMSE, p = 5, rho = 0.90, no outliers

![Figure 3.1](docs/fig3_1_mse_rho0.90_no_outlier.png)

**Table 3.1.1** - AMSE, rho = 0.90, no outliers

![Table 3.1.1](docs/table3_1_1_mse_rho0.90_no_outlier.png)

**Figure 3.4** - AMSE, rho = 0.99, 25% outliers

![Figure 3.4](docs/fig3_4_mse_rho0.99_25pct_outliers.png)

## Data

### Portland cement (`data/portland_cement.csv`)

13 observations of the heat evolved while cement hardens (Woods, Steinour & Starke, 1932).

| Column | Description |
|---|---|
| Y | Heat evolved after 180 days (calories per gram of cement) |
| X1 | Tricalcium aluminate (%) |
| X2 | Tricalcium silicate (%) |
| X3 | Tetracalcium aluminoferrite (%) |
| X4 | Dicalcium silicate (%) |

VIFs are 38.5, 254.4, 46.9 and 282.5, and the condition number is 423.73, so collinearity is severe.

![Figure 4.1](docs/fig4_1_portland_correlation.png)

### Longley

The Longley macroeconomic data (16 observations) ship with R as `datasets::longley`. VIFs reach 639 and the condition number is 293,682.5; observations 6, 10 and 16 (18.75%) are flagged as outliers.

## Repository structure

```
Ridge-Regression-Outliers/
├── R/
│   ├── simulation_no_outliers.R     # Monte Carlo study without outliers
│   └── simulation_with_outliers.R   # Monte Carlo study with 10% / 25% outliers
├── data/
│   └── portland_cement.csv
├── docs/                            # figures and tables from the paper
└── README.md
```

## How to run

```r
install.packages(c("MASS", "glmnet", "pls", "caret", "openxlsx", "psych"))
source("R/simulation_no_outliers.R")
source("R/simulation_with_outliers.R")
```

Before running:

- Set `num_simulations` to the number of replications you want (the paper uses 5000; the outlier script ships with 2 for a quick test run).
- Edit the `write.csv()` path at the end of each script to a folder on your machine.
- The scripts loop over a wider grid (p = 3, 5, 10; rho = 0.80-0.99; n up to 200) than the paper reports, so a full run takes a long time. Trim `p_values`, `rho_values` and `sample_sizes` to match the paper's design.

## Citation

```bibtex
@article{nayem2024comparison,
  title   = {Comparison among Ordinary Least Squares, Ridge, Lasso, and Elastic Net Estimators in the Presence of Outliers: Simulation and Application},
  author  = {Nayem, HM and Aziz, Sajeda and Kibria, B. M. Golam},
  journal = {International Journal of Statistical Sciences},
  volume  = {24},
  number  = {2 (Special)},
  pages   = {25--48},
  year    = {2024},
  doi     = {10.3329/ijss.v24i20.78212}
}
```

## References

Key references used in this repository (the full list of 57 is in the paper).

**Ridge, Lasso, Elastic Net and generalized ridge**

Hoerl, A. E., and Kennard, R. W. (1970). Ridge regression: Biased estimation for nonorthogonal problems. *Technometrics*, 12(1), 55-67. https://doi.org/10.1080/00401706.1970.10488634

Hoerl, A. E., Kennard, R. W., and Baldwin, K. F. (1975). Ridge regression: Some simulations. *Communications in Statistics*, 4(2), 105-123. https://doi.org/10.1080/03610927508827232

Tibshirani, R. (1996). Regression shrinkage and selection via the lasso. *Journal of the Royal Statistical Society Series B*, 58(1), 267-288. https://doi.org/10.1111/j.2517-6161.1996.tb02080.x

Zou, H., and Hastie, T. (2005). Regularization and variable selection via the elastic net. *Journal of the Royal Statistical Society Series B*, 67(2), 301-320. https://doi.org/10.1111/j.1467-9868.2005.00503.x

Yang, S.-P., and Emura, T. (2017). A Bayesian approach with generalized ridge estimation for high-dimensional regression and testing. *Communications in Statistics - Simulation and Computation*, 46(8), 6083-6105. https://doi.org/10.1080/03610918.2016.1193195

Emura, T., Matsumoto, K., Uozumi, R., and Michimae, H. (2024). g.ridge: An R package for generalized ridge regression for sparse and high-dimensional linear models. *Symmetry*, 16(2), 223. https://doi.org/10.3390/sym16020223

**Sources of the ridge parameter (k) estimators**

Mermi, S., Akkus, O., Goktas, A., and Gunduz, N. (2024). A new robust ridge parameter estimator having no outlier and ensuring normality for linear regression model. *Journal of Radiation Research and Applied Sciences*, 17(1), 100788. https://doi.org/10.1016/j.jrras.2023.100788

Kibria, B. M. G. (2023). More than hundred (100) estimators for estimating the shrinkage parameter in a linear and generalized linear ridge regression models. *Journal of Econometrics and Statistics*, 2(2), 233-252.

Kibria, B. M. G., and Lukman, A. F. (2020). A new ridge-type estimator for the linear regression model: Simulations and applications. *Scientifica*, 2020. https://doi.org/10.1155/2020/9758378

Kibria, B. M. G. (2003). Performance of some new ridge regression estimators. *Communications in Statistics - Simulation and Computation*, 32(2), 419-435. https://doi.org/10.1081/SAC-120017499

**Simulation design**

McDonald, G. C., and Galarneau, D. I. (1975). A Monte Carlo evaluation of some ridge-type estimators. *Journal of the American Statistical Association*, 70(350), 407-416. https://doi.org/10.1080/01621459.1975.10479882

Gibbons, D. G. (1981). A simulation study of some ridge estimators. *Journal of the American Statistical Association*, 76(373), 131-139. https://doi.org/10.1080/01621459.1981.10477619

**Data**

Woods, H., Steinour, H. H., and Starke, H. R. (1932). Effect of composition of Portland cement on heat evolved during hardening. *Industrial and Engineering Chemistry*, 24(11), 1207-1214. https://doi.org/10.1021/ie50275a002

Longley, J. W. (1967). An appraisal of least squares programs for the electronic computer from the point of view of the user. *Journal of the American Statistical Association*, 62(319), 819-841. https://doi.org/10.1080/01621459.1967.10500896

## Contact

HM Nayem - Department of Mathematics and Statistics, Florida International University
