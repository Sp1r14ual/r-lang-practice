# Load the httr library to get the raw content of a webpage
library(httr)
library(rvest)
library(stringi)

# URL of a page (hypothetically in windows-1251)
# Note: Finding such a page might require some searching.
# For this example, let's use a known site that often has mixed encodings.
url <- "http://lib.ru/" # A large Russian online library, good candidate

# --- Web Scraping and Analysis ---
start_time_download <- Sys.time()
# Use httr::GET to fetch the raw content without automatic encoding conversion
response <- GET(url)
raw_content <- content(response, "raw")
end_time_download <- Sys.time()

# --- Output Metrics for Real Example ---
download_time <- as.numeric(end_time_download - start_time_download)
text_volume <- length(raw_content) # in bytes

# Guess the encoding from the raw content
guessed_encoding_real <- guess_encoding(raw_content)
# The top guess is the most likely one
likely_encoding <- guessed_encoding_real$encoding[1]

# Read the content using the guessed encoding
text_content <- content(response, "text", encoding = likely_encoding)

# Here you would typically proceed to parse with rvest, e.g., read_html(text_content)

# Print results for the real example
cat(paste("URL:", url, "\n"))
cat(paste("Download Time:", round(download_time, 4), "seconds\n"))
cat(paste("Text Volume:", text_volume, "bytes\n"))
cat("Guessed Encodings:\n")
print(guessed_encoding_real)