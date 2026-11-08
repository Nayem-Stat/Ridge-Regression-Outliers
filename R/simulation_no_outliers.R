# Clear environment
rm(list = ls())

# Load necessary libraries
library(MASS)
library(glmnet)
library(pls)
library(caret)
library(openxlsx)  # For writing results to an Excel file
library(psych)

# Set parameters
sample_sizes <- c(20, 30, 50, 100, 200)  # Different sample sizes
p_values <- c(3, 5, 10)  # Number of predictors
rho_values <- c(0.80, 0.90, 0.95, 0.99)  # Different collinearity levels
beta_list <- list(c(1, 1, 1),
                  c(1, 1, 1, 1, 1),
                  c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1))  # True coefficient vector for p = 3, 5, and 7
sigma_squared_values <- c(1, 5)  # Error variance
num_simulations <- 10000  # Number of simulations
lambda_names <- c("k27", "k44", "k49", "k133", "k13", "k104", "k105", "k106", "k107", "k243", "k126", "k117", "k231", 
                  "k108", "k239", "k211", "k284", "k29", "k190", "k143", "k151", "Kck", "Kck1")  # New lambda (k) names
model_names <- c(lambda_names, "OLS","Lasso", "ElasticNet", "OptimalRidge")

set.seed(12345678)  # For reproducibility

# Function to generate the design matrix X using the specified formula
generate_X <- function(n, p, rho) {
  U <- matrix(rnorm(n * p), n, p)
  X <- sqrt(1 - rho^2) * U + rho * matrix(rep(U[, p], each = p), n, p)
  return(X)
}

# Function to compute different lambda values
compute_lambda <- function(k, sigma_squared, eigenvalues, beta_hat, beta_hat_squared, n, p) {
  q_i <- max(eigenvalues) / (((n - p) * sigma_squared) + (max(eigenvalues) * beta_hat_squared))

  lambda <- switch(k,
                   "k27" = max(1 / q_i),
                   "k44" = max((sigma_squared / beta_hat)),
                   "k49" = min(sigma_squared / ((sigma_squared / beta_hat_squared) + (1 / eigenvalues))),
                   "k133" = sqrt(p * sum(max(eigenvalues) * sigma_squared / ((n - p) * sigma_squared + max(eigenvalues) * beta_hat_squared))),
                   "k13" = median((sigma_squared / beta_hat_squared) + (1 / eigenvalues)),
                   "k104" = min((sigma_squared / beta_hat_squared) + (1 / eigenvalues)),
                   "k105" = max((sigma_squared / beta_hat_squared) + (1 / eigenvalues)),
                   "k106" = exp(mean(log(((sigma_squared / beta_hat_squared) + (1 / eigenvalues))))),
                   "k107" = harmonic.mean(((sigma_squared / beta_hat_squared) + (1 / eigenvalues))),
                   "k243" = median(max(eigenvalues) * sigma_squared / ((n - p) * sigma_squared + eigenvalues * beta_hat_squared)),
                   "k126" = max(max(eigenvalues) * sigma_squared / ((n - p) * sigma_squared + max(eigenvalues) * beta_hat_squared)),
                   "k117" = sqrt(p * sum(eigenvalues * sigma_squared / ((n - p) * sigma_squared + eigenvalues * beta_hat_squared))),
                   "k231" = sum(max((eigenvalues) * sigma_squared) / ((n - p) * sigma_squared + eigenvalues * beta_hat_squared)) / p,
                   "k108" = max(1 / ((eigenvalues * sigma_squared )/ ((n - p) * sigma_squared + eigenvalues * beta_hat_squared))),
                   "k239" = prod((max(eigenvalues) * sigma_squared) / ((n - p) * sigma_squared + eigenvalues * beta_hat_squared))^(1/p),
                   "k211" = max(1 / sqrt((eigenvalues * sigma_squared) / ((n - p) * sigma_squared + max(eigenvalues) * beta_hat_squared))),
                   "k284" = max(1 / ((eigenvalues * sigma_squared) / ((n - p) * sigma_squared + eigenvalues * max(beta_hat_squared)))),
                   "k29" = prod(1 / q_i)^(1/p),
                   "k190" = max(1 / ((eigenvalues * sigma_squared) / ((n - p) * sigma_squared + eigenvalues * max(beta_hat_squared)))),
                   "k143" = 1 / (sqrt((2 * sigma_squared) / (max(eigenvalues) * max(beta_hat_squared)))),
                   "k151" = 1 / (sqrt((2 * p * sigma_squared) / (max(eigenvalues) * sum(beta_hat_squared)))),
                   "Kck" = (sqrt(sigma_squared)) * max((p^(1+(p/n))), (p^(1+(1/p)))),
                   "Kck1"= (sqrt(sigma_squared)) * (p^(1+(p/n))),
                   stop("Unsupported k value")
  )

  # Ensure lambda is non-negative
  lambda <- ifelse(lambda < 0, abs(lambda), lambda)

  return(lambda)
}

# Function to calculate AMSE based on the provided formula
calc_AMSE <- function(beta_hat_values, beta) {
  # Calculate MSE for each simulation
  mse_values <- apply(beta_hat_values, 1, function(beta_hat) {
    sum(((beta_hat - beta)^2) / length(beta))
  })

  # Calculate mean and standard deviation of MSE
  mean_mse <- mean(mse_values)

  return(list(mean_mse = mean_mse))
}

# Create a list to store all AMSE and SD results
AMSE_SD_results_all <- list()

# Loop over each combination of p, rho, and sigma_squared
for (p_idx in seq_along(p_values)) {
  p <- p_values[p_idx]
  beta <- beta_list[[p_idx]]

  for (rho in rho_values) {
    for (sigma_squared in sigma_squared_values) {
      # Initialize a list to store AMSE and SD results
      AMSE_SD_results <- list()

      # Run simulations for each sample size
      for (n in sample_sizes) {
        AMSE_values <- setNames(vector("list", length(model_names)), model_names)
        lambda_values <- setNames(vector("list", length(lambda_names)), lambda_names)

        # Initialize the AMSE_values list with matrices for each model
        for (model_name in model_names) {
          AMSE_values[[model_name]] <- matrix(0, nrow = num_simulations, ncol = length(beta))
        }

        for (sim in 1:num_simulations) {
          X <- generate_X(n, p, rho)
          y <- X %*% beta + rnorm(n, mean = 0, sd = sqrt(sigma_squared))

          # Initialize a list to store AMSE and SD for each model
          model_results <- list()

          # Fit OLS model
          beta_hat_ols <- coef(lm(y ~ X - 1))
          AMSE_values[["OLS"]][sim, ] <- beta_hat_ols

          # Fit initial ridge regression model with a small lambda
          initial_lambda <- 0.01
          model_ridge <- glmnet(X, y, alpha = 0, lambda = initial_lambda, intercept = FALSE)
          beta_hat <- as.vector(coef(model_ridge, s = initial_lambda))[-1]  # Use a small lambda to get initial betas
          beta_hat_squared <- beta_hat^2

          eigenvalues <- eigen(cor(X))$values

          for (lambda_name in lambda_names) {
            lambda <- compute_lambda(lambda_name, sigma_squared, eigenvalues, beta_hat, beta_hat_squared, n, p)
            # Ensure lambda is non-negative and valid
            if (lambda < 0 || is.na(lambda) || is.infinite(lambda)) {
              lambda <- abs(lambda)
              cat("Warning: Negative or invalid lambda value for", lambda_name, "in simulation", sim, "\n")
            }
            lambda_values[[lambda_name]] <- lambda  # Store the computed lambda value
            model_ridge <- glmnet(X, y, alpha = 0, lambda = lambda, intercept = FALSE)
            beta_hat <- as.vector(coef(model_ridge, s = lambda))[-1]  # Use computed lambda

            AMSE_values[[lambda_name]][sim, ] <- beta_hat
          }

          # Lasso
          model_lasso <- cv.glmnet(X, y, alpha = 1, intercept = FALSE)
          beta_hat_lasso <- as.vector(coef(model_lasso, s = model_lasso$lambda.min))[-1]
          AMSE_values[["Lasso"]][sim, ] <- beta_hat_lasso

          # ElasticNet (0.5)
          model_enet <- cv.glmnet(X, y, alpha = 0.5, intercept = FALSE)
          beta_hat_enet <- as.vector(coef(model_enet, s = model_enet$lambda.min))[-1]
          AMSE_values[["ElasticNet"]][sim, ] <- beta_hat_enet

          # Optimal Ridge (using CV)
          cv_ridge <- cv.glmnet(X, y, alpha = 0, intercept = FALSE)
          beta_hat_opt_ridge <- as.vector(coef(cv_ridge, s = cv_ridge$lambda.min))[-1]
          AMSE_values[["OptimalRidge"]][sim, ] <- beta_hat_opt_ridge

          # Calculate the AMSE for each lambda and store results
          for (model_name in model_names) {
            amse_sd_results <- calc_AMSE(AMSE_values[[model_name]], beta)
            model_results[[model_name]] <- amse_sd_results
          }

          # Store model results for this simulation
          AMSE_SD_results[[sim]] <- model_results
        }

        # Store AMSE and SD results for the current sample size and sigma_squared
        AMSE_SD_results_all[[paste("n =", n, "_p =", p, "_rho =", rho, "_sigma_squared =", sigma_squared)]] <- list(AMSE_SD_results, lambda_values)
      }
    }
  }
}

# Initialize a data frame to store mean AMSE, mean SD, and lambda values
lambda_results <- data.frame(Lambda = character(0), P = numeric(0), Rho = numeric(0), n = numeric(0), sigma_squared = numeric(0),
                             K_Value = numeric(0), Mean_AMSE = numeric(0))

# Loop over each combination of p, rho, and sigma_squared
for (p_idx in seq_along(p_values)) {
  p <- p_values[p_idx]

  for (rho in rho_values) {
    for (sigma_squared in sigma_squared_values) {
      # Run simulations for each sample size
      for (n in sample_sizes) {
        # Extract AMSE and SD results for the current sample size and sigma_squared
        results <- AMSE_SD_results_all[[paste("n =", n, "_p =", p, "_rho =", rho, "_sigma_squared =", sigma_squared)]]
        AMSE_SD_results <- results[[1]]
        lambda_values <- results[[2]]

        # Initialize vectors to store mean AMSE and SD across simulations for each lambda
        mean_amse <- numeric(length(model_names))

        # Aggregate results across simulations
        for (model_idx in seq_along(model_names)) {
          model_name <- model_names[model_idx]

          # Initialize vectors to accumulate AMSE and SD across simulations
          amse_values <- numeric(num_simulations)

          for (sim in 1:num_simulations) {
            amse_sd_results <- AMSE_SD_results[[sim]][[model_name]]
            amse_values[sim] <- amse_sd_results$mean_mse
          }

          # Compute mean AMSE across simulations for the current model
          mean_amse[model_idx] <- mean(amse_values)

          # For non-k models, set k_value to NA
          k_values <- if (model_name %in% lambda_names) {
            mean(unlist(lambda_values[[model_name]]))
          } else {
            NA
          }

          # Append results to the data frame
          lambda_results <- rbind(lambda_results, data.frame(Lambda = model_name,
                                                             P = p,
                                                             Rho = rho,
                                                             n = n,
                                                             sigma_squared = sigma_squared,
                                                             K_Value = k_values,
                                                             Mean_AMSE = mean_amse[model_idx]))
        }
      }
    }
  }
}

# Print the aggregated results with lambda values and confidence intervals
print(lambda_results)

# Write results to a CSV file
write.csv(lambda_results, "C:\\Users\\hnayem\\OneDrive - Florida International University\\Documents\\new_ridge_withOut_outlier1.csv")
