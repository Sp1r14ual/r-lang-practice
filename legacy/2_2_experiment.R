library(rvest)
library(stringi)
library(ggplot2)
library(tidyr)

# --- Функции для генерации текстов ---
# Генерирует случайный русский текст заданной длины
generate_russian_text <- function(num_chars) {
  russian_alphabet <- c("а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я", " ")
  paste(sample(russian_alphabet, num_chars, replace = TRUE), collapse = "")
}

# Генерирует случайный английский текст заданной длины
generate_english_text <- function(num_chars) {
  english_alphabet <- c(letters, " ")
  paste(sample(english_alphabet, num_chars, replace = TRUE), collapse = "")
}

# Генерирует случайный французский текст заданной длины с диакритическими знаками
generate_french_text <- function(num_chars) {
  french_alphabet <- c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
                       "à", "â", "ç", "é", "è", "ê", "ë", "î", "ï", "ô", "œ", "ù", "û", "ü", "ÿ", " ")
  paste(sample(french_alphabet, num_chars, replace = TRUE), collapse = "")
}

# Генерирует случайный китайский текст заданной длины (использует популярные иероглифы)
generate_chinese_text <- function(num_chars) {
  # Примеры китайских иероглифов из набора GB2312
  chinese_characters <- c("我", "你", "他", "是", "的", "不", "在", "人", "们", "了", "来", "去", "有", "上", "下", "大", "小", "中", "国", "文", "字", "学", "习", "生", "活", "美", "好", "家", "庭", "友", "谊", "爱", "情", "和", "平", "世", "界", "语", "言", "计", "算", "机", "科", "技", "发", "展", "创", "新")
  paste(sample(chinese_characters, num_chars, replace = TRUE), collapse = "")
}


# --- Параметры эксперимента ---
# Различные размеры текстовых фрагментов
sample_sizes <- c(50, 100, 500, 1000, 5000, 10000)

# Тестовые случаи: язык и соответствующие ему кодировки
test_cases <- data.frame(
  Language = c("Russian", "Russian", "Russian", "English", "English", "French", "French", "Chinese", "Chinese"),
  TrueEncoding = c("UTF-8", "windows-1251", "KOI8-R", "UTF-8", "ISO-8859-1", "UTF-8", "ISO-8859-1", "UTF-8", "GB18030")
)

# Создаем пустой data.frame для сбора результатов
results <- data.frame()

# --- Запускаем цикл по всем условиям ---
for (i in 1:nrow(test_cases)) {
  lang <- test_cases$Language[i]
  encoding <- test_cases$TrueEncoding[i]

  for (size in sample_sizes) {
    # Создаем исходный текст в зависимости от языка
    original_text <- switch(lang,
      "Russian" = generate_russian_text(size),
      "English" = generate_english_text(size),
      "French" = generate_french_text(size),
      "Chinese" = generate_chinese_text(size)
    )

    # Конвертируем текст в "сырые" байты с нужной кодировкой
    text_raw <- stri_encode(original_text, from = "UTF-8", to = encoding)

    # --- Тестирование guess_encoding ---
    start_time_guess <- Sys.time()
    guessed <- guess_encoding(text_raw)
    end_time_guess <- Sys.time()
    time_guess <- as.numeric(end_time_guess - start_time_guess)

    # Определяем, была ли угадана кодировка
    is_guess_correct <- ifelse(nrow(guessed) > 0, guessed$encoding[1] == encoding, FALSE)

    # --- Тестирование repair_encoding ---
    # Создаем "испорченный" текст (mojibake)
    garble_encoding <- "ISO-8859-5"
    garbled_text <- stri_conv(text_raw, from = encoding, to = garble_encoding)

    start_time_repair <- Sys.time()
    # Восстанавливаем текст, предполагая неверную кодировку
    repaired_text <- repair_encoding(garbled_text, from=garble_encoding)
    end_time_repair <- Sys.time()
    time_repair <- as.numeric(end_time_repair - start_time_repair)
    
    # Проверяем, удалось ли восстановить текст
    is_repair_correct <- (repaired_text == original_text)

    # Сохраняем результаты в таблицу
    results <- rbind(results, data.frame(
      Language = lang,
      SampleSize = size,
      TrueEncoding = encoding,
      GuessedCorrectly = is_guess_correct,
      TimeGuess = time_guess,
      RepairedCorrectly = is_repair_correct,
      TimeRepair = time_repair
    ))
  }
}

print("Результаты комплексного эксперимента:")
print(results)

# График точности угадывания
# Вместо geom_bar используем stat_summary с geom_line и geom_point
accuracy_plot <- ggplot(results, aes(x = TrueEncoding, y = GuessedCorrectly, color = GuessedCorrectly)) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  labs(
    title = "Точность угадывания кодировки (guess_encoding)",
    x = "Исходная кодировка",
    y = "Средняя точность"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("TRUE" = "green", "FALSE" = "red"), guide = "none") +
  facet_wrap(~ Language, scales = "free_x") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(accuracy_plot)


# График скорости выполнения guess_encoding
speed_guess_plot <- ggplot(results, aes(x = SampleSize, y = TimeGuess, color = TrueEncoding)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ Language, scales = "free_x") +
  labs(
    title = "Скорость guess_encoding в зависимости от размера текста",
    x = "Размер текста (символы)",
    y = "Время (сек)"
  ) +
  theme_minimal()

print(speed_guess_plot)