import chardet
import ftfy
import random
import time
import pandas as pd

# Function to generate random Russian text
def generate_russian_text(num_chars):
    russian_alphabet = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя "
    return "".join(random.choices(russian_alphabet, k=num_chars))

# Experimental parameters
sample_sizes = [50, 100, 500, 1000]
true_encodings = ["utf-8", "windows-1251", "koi8-r"]

results_py = []

for size in sample_sizes:
    for encoding in true_encodings:
        # Generate and encode text
        original_text = generate_russian_text(size)
        raw_bytes = original_text.encode(encoding)

        # --- Test chardet (equivalent to guess_encoding) ---
        start_time_guess = time.time()
        guess = chardet.detect(raw_bytes)
        end_time_guess = time.time()
        time_guess = end_time_guess - start_time_guess

        # --- Test ftfy (equivalent to repair_encoding) ---
        # Simulate reading with wrong encoding
        garbled_text = raw_bytes.decode('iso-8859-1')

        start_time_repair = time.time()
        repaired_text = ftfy.fix_text(garbled_text)
        end_time_repair = time.time()
        time_repair = end_time_repair - start_time_repair

        results_py.append({
            "SampleSize": size,
            "TrueEncoding": encoding,
            "TimeGuess": time_guess,
            "GuessedCorrectly": guess['encoding'] == encoding,
            "TimeRepair": time_repair,
            "RepairedCorrectly": repaired_text == original_text
        })

df_py = pd.DataFrame(results_py)
print("Python Model Experiment Results:")
print(df_py)