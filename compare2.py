import pandas as pd
import chardet
import ftfy
import time
import matplotlib.pyplot as plt
import seaborn as sns

# 1. Создаем набор осмысленных текстовых фрагментов на разных языках
sample_texts = {
    "Russian": "«Война и мир» — роман-эпопея Льва Николаевича Толстого, описывающий русское общество в эпоху войн против Наполеона.",
    "French": "Aujourd'hui, maman est morte. Ou peut-être hier, je ne sais pas. C'est une célèbre citation.",
    "Chinese": "学如逆水行舟，不进则退。 这是一个著名的中国谚语，意思是学习就像逆水行舟，不前进就会后退。",
    "English_Simple": "This is a simple sentence in English containing only basic ASCII characters.",
    "English_Complex": "He said, “That’s a ‘smart’ quote.” This text uses special characters – like an em dash."
}

# 2. Определяем тестовые случаи в виде списка словарей
test_cases = [
    {"Language": "Russian", "TextKey": "Russian", "TrueEncoding": "utf-8"},
    {"Language": "Russian", "TextKey": "Russian", "TrueEncoding": "windows-1251"},
    {"Language": "French", "TextKey": "French", "TrueEncoding": "utf-8"},
    {"Language": "French", "TextKey": "French", "TrueEncoding": "iso-8859-1"},
    {"Language": "Chinese", "TextKey": "Chinese", "TrueEncoding": "utf-8"},
    {"Language": "Chinese", "TextKey": "Chinese", "TrueEncoding": "gb18030"},
    {"Language": "English_Simple", "TextKey": "English_Simple", "TrueEncoding": "ascii"},
    {"Language": "English_Complex", "TextKey": "English_Complex", "TrueEncoding": "utf-8"},
    {"Language": "English_Complex", "TextKey": "English_Complex", "TrueEncoding": "windows-1252"}
]

# Список для хранения результатов
results_list = []

# 3. Запускаем цикл по тестовым случаям
for case in test_cases:
    lang = case["Language"]
    text_key = case["TextKey"]
    encoding = case["TrueEncoding"]
    original_text = sample_texts[text_key]

    # Кодируем текст в "сырые" байты
    raw_bytes = original_text.encode(encoding)

    # --- Тестируем chardet (аналог guess_encoding) ---
    start_time_guess = time.perf_counter()
    guess = chardet.detect(raw_bytes)
    end_time_guess = time.perf_counter()
    time_guess = end_time_guess - start_time_guess
    
    # chardet может возвращать имена в нижнем регистре, приводим все к одному виду
    top_guess = guess['encoding']
    is_guess_correct = top_guess.lower() == encoding.lower()

    # --- Тестируем ftfy (аналог repair_encoding) ---
    # Имитируем ошибку: декодируем байты в неправильной кодировке
    garbled_text = raw_bytes.decode('iso-8859-1')
    
    start_time_repair = time.perf_counter()
    repaired_text = ftfy.fix_text(garbled_text)
    end_time_repair = time.perf_counter()
    time_repair = end_time_repair - start_time_repair
    
    is_repair_correct = (repaired_text == original_text)

    # Сохраняем все результаты
    results_list.append({
        "Language": lang,
        "TrueEncoding": encoding,
        "GuessedCorrectly": is_guess_correct,
        "RepairedCorrectly": is_repair_correct,
        "TimeGuess": time_guess,
        "TimeRepair": time_repair
    })

# Преобразуем список результатов в DataFrame
results_df = pd.DataFrame(results_list)

print("Результаты комплексного эксперимента на Python:")
print(results_df)

# 4. Визуализация результатов

# График точности угадывания
g_accuracy = sns.catplot(
    data=results_df,
    x="TrueEncoding",
    hue="GuessedCorrectly",
    col="Language",
    kind="count",
    palette={True: "green", False: "red"},
    sharex=False # Не синхронизировать ось X между графиками
)
g_accuracy.fig.suptitle("Точность угадывания кодировки (chardet)", y=1.03)
g_accuracy.set_axis_labels("Исходная кодировка", "Количество тестов")
g_accuracy.set_titles("Язык: {col_name}")
plt.xticks(rotation=45)

plt.savefig("accuracy.png")

# График скорости выполнения
# Преобразуем данные в "длинный" формат
results_long = results_df.melt(
    id_vars=["Language", "TrueEncoding"],
    value_vars=["TimeGuess", "TimeRepair"],
    var_name="Function",
    value_name="Time"
)

g_speed = sns.catplot(
    data=results_long,
    x="TrueEncoding",
    y="Time",
    hue="Function",
    col="Language",
    kind="bar",
    sharex=False
)
g_speed.fig.suptitle("Скорость выполнения функций", y=1.03)
g_speed.set_axis_labels("Исходная кодировка", "Время (секунды)")
g_speed.set_titles("Язык: {col_name}")
plt.xticks(rotation=45)

plt.tight_layout()
plt.savefig("speed.png")
plt.show()