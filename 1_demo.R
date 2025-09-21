# install.packages(c("rvest", "stringi"), repos = "http://cran.us.r-project.org")

# Load necessary libraries
library(rvest)
library(stringi)

# --- guess_encoding Function ---
# Purpose: To guess the character encoding of a raw byte stream.

# Input parameter:
# x: A raw vector containing the text data.

# Output:
# A tibble with two columns:
# - encoding: The suggested encoding name (e.g., "UTF-8", "ISO-8859-1").
# - confidence: A numeric value from 0 to 1 indicating the confidence in the guess.

# Example usage:
# Let's create a text string and convert it to a different encoding
text_utf8 <- "Это пример текста на русском языке."
# Convert the string to a raw vector in a specific encoding (e.g., KOI8-R)
text_raw_koi8r <- stri_encode(text_utf8, from = "UTF-8", to = "KOI8-R")

# Guess the encoding from the raw vector
guessed_encodings <- guess_encoding(text_raw_koi8r)
print("Guessed Encodings:")
print(guessed_encodings)


# --- repair_encoding Function ---
# Purpose: To repair a character vector that has encoding issues.

# Input parameters:
# x: A character vector with mojibake or other encoding problems.
# from: (Optional) The name of the encoding to assume the text was originally in.

# Output:
# A character vector with the repaired text.

# Example usage:
# Let's simulate a common issue: reading KOI8-R text as if it were Latin1 (ISO-8859-1)
# This creates garbled text (mojibake)
# garbled_text <- stri_conv(text_raw_koi8r, from = "KOI8-R", to = "ISO-8859-1")
garbled_text <- stri_conv(text_raw_koi8r, from = "KOI8-R", to = "ISO-8859-5")
print(paste("Garbled Text:", garbled_text))

# Repair the text. The function will try to auto-detect the issue.
repaired_text <- repair_encoding(garbled_text)
print(paste("Repaired Text:", repaired_text))