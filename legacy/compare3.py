import pandas as pd
import chardet
import ftfy
import time
import matplotlib.pyplot as plt
import seaborn as sns
import random

# --- Functions for text generation ---
# Generates random Russian text of a given length
def generate_russian_text(num_chars):
    russian_alphabet = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя "
    return "".join(random.choices(russian_alphabet, k=num_chars))

# Generates random English text of a given length
def generate_english_text(num_chars):
    english_alphabet = "abcdefghijklmnopqrstuvwxyz "
    return "".join(random.choices(english_alphabet, k=num_chars))

# Generates random French text of a given length with diacritics
def generate_french_text(num_chars):
    french_alphabet = "abcdefghijklmnopqrstuvwxyzàâçéèêëîïôœùûüÿ "
    return "".join(random.choices(french_alphabet, k=num_chars))

# Generates random Chinese text of a given length using common characters
def generate_chinese_text(num_chars):
    chinese_characters = "我你他是的不在人们了来去有上下大小中国文字学习生活美好家庭友谊爱情和平世界语言计算机科技发展创新"
    return "".join(random.choices(chinese_characters, k=num_chars))

# --- Experiment parameters ---
# Different text sizes
sample_sizes = [50, 100, 500, 1000, 5000, 10000]

# Test cases: language and corresponding encodings
test_cases = [
    {"Language": "Russian", "TrueEncoding": "utf-8"},
    {"Language": "Russian", "TrueEncoding": "windows-1251"},
    {"Language": "Russian", "TrueEncoding": "KOI8-R"},
    {"Language": "English", "TrueEncoding": "utf-8"},
    {"Language": "English", "TrueEncoding": "cp1252"},
    {"Language": "French", "TrueEncoding": "utf-8"},
    {"Language": "French", "TrueEncoding": "cp1252"},
    {"Language": "Chinese", "TrueEncoding": "utf-8"},
    {"Language": "Chinese", "TrueEncoding": "gb18030"}
]

# List to store results
results_list = []

# --- Run the experiment loop ---
for case in test_cases:
    lang = case["Language"]
    encoding = case["TrueEncoding"]

    for size in sample_sizes:
        # Create the original text based on the language
        if lang == "Russian":
            original_text = generate_russian_text(size)
        elif lang == "English":
            original_text = generate_english_text(size)
        elif lang == "French":
            original_text = generate_french_text(size)
        elif lang == "Chinese":
            original_text = generate_chinese_text(size)
        
        # Encode the text into "raw" bytes
        raw_bytes = original_text.encode(encoding)

        # --- Test chardet (analogous to guess_encoding) ---
        start_time_guess = time.perf_counter()
        guess = chardet.detect(raw_bytes)
        end_time_guess = time.perf_counter()
        time_guess = end_time_guess - start_time_guess
        
        # Normalize encoding names for comparison
        top_guess = guess['encoding'].lower() if guess['encoding'] else None
        is_guess_correct = top_guess == encoding.lower()

        # --- Test ftfy (analogous to repair_encoding) ---
        # Simulate an encoding error (mojibake)
        garble_encoding = "iso-8859-5"
        try:
            garbled_text = raw_bytes.decode(garble_encoding)
        except UnicodeDecodeError:
            garbled_text = raw_bytes.decode(encoding, errors='ignore')

        start_time_repair = time.perf_counter()
        # ftfy attempts to automatically fix the mojibake
        repaired_text = ftfy.fix_text(garbled_text)
        end_time_repair = time.perf_counter()
        time_repair = end_time_repair - start_time_repair
        
        is_repair_correct = (repaired_text == original_text)

        # Save all results to the list
        results_list.append({
            "Language": lang,
            "SampleSize": size,
            "TrueEncoding": encoding,
            "GuessedCorrectly": is_guess_correct,
            "TimeGuess": time_guess,
            "RepairedCorrectly": is_repair_correct,
            "TimeRepair": time_repair
        })

# Convert the list of results to a DataFrame
results_df = pd.DataFrame(results_list)

print("Comprehensive Python Experiment Results:")
print(results_df)

# --- Visualization ---

# Plot 1: Encoding guess accuracy vs. true encoding
# Use a catplot to create a bar chart for each language
g_accuracy = sns.catplot(
    data=results_df,
    x="TrueEncoding",
    y="GuessedCorrectly",
    hue="GuessedCorrectly",
    col="Language",
    kind="point",
    palette={True: "green", False: "red"},
    join=False,  # Do not connect points
    dodge=True,
    sharex=False
)
g_accuracy.fig.suptitle("Encoding Guessing Accuracy (chardet)", y=1.03)
g_accuracy.set_axis_labels("Original Encoding", "Accuracy")
g_accuracy.set_titles(col_template="Language: {col_name}")
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
plt.savefig("accuracy.png")
plt.show()

# Plot 2: Speed of guess_encoding vs. text size
# Use a relplot for a line graph with facets
g_speed_guess = sns.relplot(
    data=results_df,
    x="SampleSize",
    y="TimeGuess",
    hue="TrueEncoding",
    col="Language",
    kind="line",
    style="TrueEncoding",
    markers=True,
    dashes=False,
    facet_kws={'sharey': False, 'sharex': True}
)
g_speed_guess.fig.suptitle("chardet Speed vs. Text Size", y=1.03)
g_speed_guess.set_axis_labels("Text Size (characters)", "Time (seconds)")
g_speed_guess.set_titles(col_template="Language: {col_name}")
plt.tight_layout()
plt.savefig("speed.png")
plt.show()