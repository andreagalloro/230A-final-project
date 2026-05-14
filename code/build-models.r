####
# This r module should be run in the main final-project directory by calling
# source("code/build-models.r")
# in an r session. builds and compares multiple modes on the data.
####

cat("Loading libraries...\n")
library(tidyverse)
library(tis)
library(baseballr)
library(hoopR)
library(MASS)
library(glmnet)
library(mpath)
library(glmmTMB)
library(Matrix)
library(lmtest)
library(car)

######################### Data Preparation #########################

# Load in Data
cat("Loading final dataset...\n")
df <- read_csv("./data/final-dataset.csv")

# Split into Training and Testing sets. Treat hour as a factor.
cat("Splitting data into train and test...\n")
train <- df %>%
  filter(year(date) < 2025) %>%
  mutate(hour = as_factor(hour))
test <- df %>%
  filter(year(date) == 2025) %>%
  mutate(hour = as_factor(hour))

# For Ridge Poisson, Ridge NB and Zero-Inflated NB GLM
# Remove the intercept since glmnet adds it automatically
model_formula <- as.formula("ridership ~ hour + destination + day + is_holiday + is_giants_home + is_as_home + warriors_at_chase + season - 1")
X_train <- model.matrix(model_formula, data = train)
y_train <- train$ridership

X_test <- model.matrix(model_formula, data = test)
y_test <- test$ridership

# replacing 0's with 1's for the 
# log-transformed model
train_log <- train |> mutate(ridership = if_else(ridership == 0, 1, ridership))
test_log <- test |> mutate(ridership = if_else(ridership == 0, 1, ridership))

n <- nrow(train)
fold_size <- floor(n / 5)

foldid <- rep(1:5, each = fold_size, length.out = n)

######################### Model Building #########################
cat("Building basic models...\n")
cat("Building basic linear model...\n")
# Basic Linear Model
basic_lm <- lm(ridership ~ ., data = train[, -c(1)])

cat("Building basic log-transformed linear model...\n")
# Log-Transformed LM
log_lm <- lm(log(ridership) ~ ., data = train_log[, -c(1)])

# Poisson GLM
cat("Building Poisson linear model...\n")
poisson_lm <- glm(ridership ~ ., data = train[, -c(1)], family = poisson(link = "log"))

# Negative Binomial Model
cat("Building negative binomial model...\n")
nb_lm <- glm.nb(ridership ~ ., data = train[, -c(1)])

# Poisson GLM with Ridge selected by 5-fold CV

# Ridge Poisson - selected using 5-fold CV
cat("Performing cross-validation for Poisson regularization factor...\n")
cv_ridge_poisson <- cv.glmnet(
  x = X_train,
  y = y_train,
  family = "poisson",
  alpha = 0, # 0 for ridge, 1 for LASSO
  foldid = foldid
)

# Best lambda
best_lambda_poisson <- cv_ridge_poisson$lambda.min

# Fit Final Ridge Poisson Model
cat("Building final ridge Poisson model...\n")
poisson_ridge <- glmnet(
  x = X_train,
  y = y_train,
  family = "poisson",
  alpha = 0, # 0 for ridge, 1 for LASSO
  lambda = best_lambda_poisson
)

# Ridge NB - selected using Validation Set
cat("Starting regularization factor search for NB model...\n")
sub_train <- train %>% filter(year(date) == 2023)
sub_val <- train %>% filter(year(date) == 2024)

X_sub_train <- sparse.model.matrix(model_formula, data = sub_train)
X_sub_val <- sparse.model.matrix(model_formula, data = sub_val)

y_sub_train <- sub_train$ridership
y_sub_val <- sub_val$ridership

cat("Estimating theta...\n")
# First, estimate theta from a small, unregularized fit
nb_for_theta <- glm.nb(
  ridership ~ hour + destination + day + is_holiday +
    is_giants_home + is_as_home + warriors_at_chase + season,
  data = sub_train
)
theta_est <- nb_for_theta$theta
cat("Estimated theta:", theta_est, "\n")

lambdas <- 10^seq(2, -3, length.out = 10)
mse_results <- numeric(length(lambdas))

# Loop through lambdas
cat("Evaualting different lambdas using 2024 data as validation...\n")
for (i in seq_along(lambdas)) {
  fit <- glmnet(
    x = X_sub_train,
    y = y_sub_train,
    family = negative.binomial(theta = theta_est),
    alpha = 0,
    lambda = lambdas[i]
  )

  # Predict on 2024 data
  preds <- as.numeric(predict(fit, newx = X_sub_val, type = "response"))
  mse_results[i] <- mean((y_sub_val - preds)^2)
  message(sprintf("Lambda: %8.5f | MSE: %.2f", lambdas[i], mse_results[i]))
}

best_lambda_nb <- lambdas[which.min(mse_results)]
cat("Best lambda (Ridge NB):", best_lambda_nb, "\n")

# Re-estimate theta on full training set
cat("Reestimating theta from full training...\n")
nb_for_theta_full <- glm.nb(
  ridership ~ hour + destination + day + is_holiday + is_giants_home + is_as_home + warriors_at_chase + season,
  data = train
)

cat("Building final ridge NB model...\n")
nb_ridge <- glmnet(
  x = X_train,
  y = y_train,
  family = negative.binomial(theta = nb_for_theta_full$theta),
  alpha = 0,
  lambda = best_lambda_nb
)

# Zero-inflated NB
cat("Building zero-inflated NB model...\n")
model_zinb <- glmmTMB(
  ridership ~ hour + destination + day + is_holiday + is_giants_home + is_as_home + warriors_at_chase + season,
  data = train,
  ziformula = ~1,
  family = nbinom2 # nbinom2 = NB with quadratic variance (same as glm.nb)
)

######################### Model Testing #########################

cat("Testing models...\n")

# Helper to compute MSE and RMSE cleanly
eval_preds <- function(preds, actual) {
  mse <- mean((actual - preds)^2)
  rmse <- sqrt(mse)
  list(mse = mse, rmse = rmse)
}

# Model 1: Basic LM
cat("Testing basic LM...\n")
preds_lm <- predict(basic_lm, newdata = test)
# Clip negatives: LM has no non-negativity constraint, but ridership can't be negative
preds_lm <- pmax(preds_lm, 0)
result_lm <- eval_preds(preds_lm, y_test)

# Model 2: Log-transformed LM
cat("Testing log-transformed LM...\n")
# E[Y] = exp(mu + sigma^2/2) when residuals are normal in log space.
# Correction factor exp(sigma^2/2) makes the back-transformed prediction unbiased.
# We should check the residual plot of this model to check the appropriateness of this correction factor.
sigma2_log_lm <- var(residuals(log_lm))
preds_log_lm <- exp(predict(log_lm, newdata = test_log)) * exp(sigma2_log_lm / 2)
result_log_lm <- eval_preds(preds_log_lm, y_test)

# Model 3: Poisson GLM
cat("Testing Poisson GLM...\n")
preds_poisson <- predict(poisson_lm, newdata = test, type = "response")
result_poisson <- eval_preds(preds_poisson, y_test)

# Model 4: NB GLM
cat("Testing NB GLM...\n")
preds_nb <- predict(nb_lm, newdata = test, type = "response")
result_nb <- eval_preds(preds_nb, y_test)

# Model 5: Ridge Poisson
cat("Testing Poisson Ridge...\n")
preds_poisson_ridge <- as.numeric(predict(poisson_ridge, newx = X_test, type = "response"))
result_poisson_ridge <- eval_preds(preds_poisson_ridge, y_test)

# Model 6: Ridge NB
cat("Testing ridge NB...\n")
preds_nb_ridge <- as.numeric(predict(nb_ridge, newx = X_test, type = "response"))
result_nb_ridge <- eval_preds(preds_nb_ridge, y_test)

# Model 7: Zero-Inflated NB
cat("Testing zero-inlfated NB...\n")
preds_zinb <- predict(model_zinb, newdata = test, type = "response")
result_zinb <- eval_preds(preds_zinb, y_test)

# Print Results
results <- tibble(
  Model = c(
    "Basic LM",
    "Log-Transformed LM (bias-corrected)",
    "Poisson GLM",
    "Negative Binomial GLM",
    "Ridge Poisson (lambda = 7.082)",
    "Ridge NB (lambda = 0.599)",
    "Zero-Inflated NB"
  ),
  Lambda_Selection = c(
    "—", "—", "—", "—",
    "5-fold time-based CV",
    "Validation set (2023 train / 2024 val)",
    "—"
  ),
  Test_MSE = round(c(
    result_lm$mse, result_log_lm$mse, result_poisson$mse,
    result_nb$mse, result_poisson_ridge$mse,
    result_nb_ridge$mse, result_zinb$mse
  ), 2),
  Test_RMSE = round(c(
    result_lm$rmse, result_log_lm$rmse, result_poisson$rmse,
    result_nb$rmse, result_poisson_ridge$rmse,
    result_nb_ridge$rmse, result_zinb$rmse
  ), 2)
)
cat("Final Results:\n")
print(results)

cat("Saving model and results...\n")
# save model testing results
write_csv(x = results, file = "report/final/modelling-results.csv")
# save final model
write_rds(x = poisson_lm, file = "report/final/poisson-lm.rds")

cat("Done!\n")

