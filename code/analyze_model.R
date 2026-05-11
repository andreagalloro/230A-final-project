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

setwd("..")

df <- read_csv("./data/final-dataset.csv")

# Split into Training and Testing sets. Treat hour as a factor.
train <- df %>%
  filter(year(date) < 2025) %>%
  mutate(hour = as_factor(hour))
test <- df %>%
  filter(year(date) == 2025) %>%
  mutate(hour = as_factor(hour))

# Train Model
poisson_lm <- glm(ridership ~ ., data = train[, -c(1)], family = poisson(link = "log"))

y_train <- train$ridership
y_test <- test$ridership

eval_preds <- function(preds, actual) {
  mse <- mean((actual - preds)^2)
  rmse <- sqrt(mse)
  list(mse = mse, rmse = rmse)
}

# Prediction on Test Set
preds_poisson <- predict(poisson_lm, newdata = test, type = "response")
result_poisson <- eval_preds(preds_poisson, y_test)

# Train Full Poisson (v1)
full <- df %>% mutate(hour = as_factor(hour))

poisson_full <- glm(ridership ~ ., data = full[, -c(1)], family = poisson(link = "log"))

# Analysis 1: High Residual Points
pearson_resid <- residuals(poisson_full, type = "pearson")
leverage <- hatvalues(poisson_full)

resid_df <- tibble(
  destination = full$destination,
  hour = full$hour,
  day = full$day,
  is_holiday = full$is_holiday,
  fitted = fitted(poisson_full),
  pearson_resid = pearson_resid,
  leverage = leverage,
  abs_resid = abs(pearson_resid)
)

print(resid_df %>%
  arrange(desc(abs_resid)) %>%
  filter(leverage < median(leverage)) %>%
  head(20))

# Analysis 2: Stratified Prediction
test_annotated <- test %>%
  mutate(
    pred = preds_poisson,
    residual = ridership - pred,
    sq_error = residual^2,
    period = case_when(
      as.integer(as.character(hour)) %in% 7:9 ~ "AM Peak",
      as.integer(as.character(hour)) %in% 16:18 ~ "PM Peak",
      TRUE ~ "Off-Peak"
    ),
    day_type = ifelse(day %in% c("saturday", "sunday"), "weekend", "weekday")
  )

print(
  test_annotated %>%
    group_by(day_type, period) %>%
    summarise(
      RMSE = sqrt(mean(sq_error)),
      MAE = mean(abs(residual)),
      n = n()
    ) %>%
    arrange(desc(n))
)

# Analysis 3: Overdispersion Check
nb_lm <- glm.nb(ridership ~ ., data = train[, -c(1)])

lrtest(nb_lm, poisson_lm)
nb_lm$theta

# Build Full Poisson (v2) with interactions, Training + Testing
poisson_lm2 <- glm(ridership ~ destination + hour * day + is_holiday + is_giants_home + is_as_home + warriors_at_chase + season, data = train[, -c(1)], family = poisson(link = "log"))
summary(poisson_lm2)

# Prediction on Test Set
preds_poisson2 <- predict(poisson_lm2, newdata = test, type = "response")
result_poisson2 <- eval_preds(preds_poisson2, y_test)

print(result_poisson2)

# Full Poisson Model with Interactions on Full Dataset
poisson_final <- glm(ridership ~ destination + hour * day + is_holiday + is_giants_home + is_as_home + warriors_at_chase + season, data = full[, -c(1)], family = poisson(link = "log"))
summary(poisson_final)

# Plot Residuals vs. Fitted Values
png("./figs/residuals_fitted_poisson_final.png")
plot(poisson_final, which = 1)
dev.off() 

# Plot Leverage vs. Residuals
png("./figs/leverage_residuals_poisson_final.png")
plot(poisson_final, which = 4)
dev.off() 

# VIF Of Final Model
vif(poisson_final)

# Rootogram of Final Model
# Observed Counts and model-fitted values
observed <- full$ridership
expected <- fitted(poisson_final)

# Build observed and expected frequency tables over count values
max_count <- quantile(observed, 0.99) # trim extreme tail for readability
count_vals <- 0:max_count

obs_freq <- tabulate(observed + 1)[1:(max_count + 1)]
obs_freq[is.na(obs_freq)] <- 0

# Expected frequencies: sum predicted probabilities across all observations
# For Poisson, P(Y=k | mu_i) = dpois(k, mu_i)
exp_freq <- sapply(count_vals, function(k) sum(dpois(k, lambda = expected)))

rootogram_df <- tibble(
  count = count_vals,
  observed = obs_freq,
  expected = exp_freq,
  sqrt_obs = sqrt(obs_freq),
  sqrt_exp = sqrt(exp_freq),
  # "hanging": bar bottom is sqrt_exp - sqrt_obs, top is sqrt_exp
  bar_top = sqrt_exp,
  bar_bot = sqrt_exp - sqrt_obs
)

ggplot(rootogram_df, aes(x = count)) +
  geom_rect(
    aes(
      xmin = count - 0.45, xmax = count + 0.45,
      ymin = bar_bot, ymax = bar_top
    ),
    fill = "blue", color = "blue", linewidth = 0.2
  ) +
  geom_line(aes(y = sqrt_exp), color = "red", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  labs(
    title = "Hanging Rootogram: Poisson Model",
    subtitle = "Bars hanging below zero = underpredicted; above zero = overpredicted",
    x = "Ridership Count",
    y = "sqrt(Frequency)"
  ) +
  theme_minimal()
ggsave("./figs/rootogram_poisson.png", width = 8, height = 5)

# Demonstrate Autocorrelation
# Plot of ridership over time
key_stations <- c("EMBR", "MONT", "POWL", "CIVC", "OAKL", "FRMT", "ANTC", "PCTR")

df %>%
  filter(destination %in% key_stations) %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, destination) %>%
  summarise(total_ridership = sum(ridership), .groups = "drop") %>%
  ggplot(aes(x = month, y = total_ridership, color = destination)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Monthly Ridership Over Time: Selected Stations",
    x = "Month",
    y = "Monthly Ridership",
    color = "Station"
  ) +
  theme_minimal()
ggsave("./figs/monthly_ridership.png", width = 8, height = 5)

# ACF Plot to Show Autocorrelation
daily_ridership <- df %>%
  group_by(date) %>%
  summarise(total_ridership = sum(ridership), .groups = "drop") %>%
  arrange(date)

acf_values <- acf(daily_ridership$total_ridership, lag.max = 60, plot = FALSE)

# Confidence interval threshold: +/- 1.96 / sqrt(n)
ci <- qnorm(0.975) / sqrt(nrow(daily_ridership))

acf_df <- tibble(
  lag = as.numeric(acf_values$lag),
  acf = as.numeric(acf_values$acf)
)

ggplot(acf_df, aes(x = lag, y = acf)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(ci, -ci), linetype = "dashed", color = "blue") +
  geom_segment(aes(xend = lag, yend = 0), color = "steelblue") +
  geom_point(size = 1.5, color = "steelblue") +
  labs(
    title = "ACF of Daily Total BART Ridership",
    subtitle = "Dashed lines indicate 95% confidence bounds",
    x = "Lag (days)",
    y = "Autocorrelation"
  ) +
  theme_minimal()
ggsave("./figs/acf_ridership.png", width = 8, height = 5)