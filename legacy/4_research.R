library(ggplot2)

# How does computation time depend on sample size?
ggplot(results, aes(x = SampleSize, y = TimeGuess, color = TrueEncoding)) +
  geom_line() +
  labs(title = "guess_encoding Time vs. Sample Size", x = "Text Size (characters)", y = "Time (seconds)")

# How does accuracy depend on sample size?
ggplot(results, aes(x = SampleSize, y = as.numeric(GuessedCorrectly), color = TrueEncoding)) +
  stat_summary(fun = mean, geom = "line") +
  labs(title = "guess_encoding Accuracy vs. Sample Size", x = "Text Size (characters)", y = "Accuracy")