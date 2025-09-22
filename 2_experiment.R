library(rvest)
library(stringi)
library(ggplot2)

# Function to generate random Russian text
generate_russian_text <- function(num_chars) {
  russian_alphabet <- c("а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я", " ")
  paste(sample(russian_alphabet, num_chars, replace = TRUE), collapse = "")
}

generate_english_text <- function(num_chars) {
  # russian_alphabet <- c("а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я", " ")
  english_alphabet <- c(letters, " ")
  paste(sample(english_alphabet, num_chars, replace = TRUE), collapse = "")
}

# Experimental parameters
sample_sizes <- c(50, 100, 500, 1000)
true_encodings <- c("UTF-8", "windows-1251", "KOI8-R", "KOI-8U", "CP-866", "ISO-8859-5")

# Data frame to store results
results <- data.frame()

# Loop through all conditions
for (size in sample_sizes) {
  for (encoding in true_encodings) {
    # Generate original text
    original_text <- generate_russian_text(size)

    # Convert to raw vector in the "true" encoding
    text_raw <- stri_encode(original_text, from = "UTF-8", to = encoding)

    # --- Test guess_encoding ---
    start_time_guess <- Sys.time()
    guessed <- guess_encoding(text_raw)
    end_time_guess <- Sys.time()
    time_guess <- as.numeric(end_time_guess - start_time_guess)

    # --- Test repair_encoding ---
    # Simulate reading the file with the wrong encoding (a common source of errors)
    garble_encoding <- "ISO-8859-5"
    garbled_text <- stri_conv(text_raw, from = encoding, to = garble_encoding)

    start_time_repair <- Sys.time()
    # repaired_text <- repair_encoding(garbled_text, from = encoding)
    repaired_text <- repair_encoding(garbled_text, from = garble_encoding)
    end_time_repair <- Sys.time()
    time_repair <- as.numeric(end_time_repair - start_time_repair)

    # Store results
    results <- rbind(results, data.frame(
      SampleSize = size,
      TrueEncoding = encoding,
      TimeGuess = time_guess,
      GuessedCorrectly = ifelse(nrow(guessed) > 0, guessed$encoding[1] == encoding, FALSE),
      TimeRepair = time_repair,
      RepairedCorrectly = (repaired_text == original_text) # Невосстанавливается текст, изучить
    ))
  }
}

print("Model Experiment Results:")
print(results)

# How does computation time depend on sample size?
ggplot(results, aes(x = SampleSize, y = TimeGuess, color = TrueEncoding)) +
  geom_line() +
  labs(title = "guess_encoding Time vs. Sample Size", x = "Text Size (characters)", y = "Time (seconds)")

# How does accuracy depend on sample size?
ggplot(results, aes(x = SampleSize, y = as.numeric(GuessedCorrectly), color = TrueEncoding)) +
  stat_summary(fun = mean, geom = "line") +
  labs(title = "guess_encoding Accuracy vs. Sample Size", x = "Text Size (characters)", y = "Accuracy")