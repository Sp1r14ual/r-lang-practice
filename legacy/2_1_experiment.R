# Загружаем необходимые библиотеки
library(rvest)
library(stringi)
library(ggplot2)
library(tidyr)

# 1. Создаем набор осмысленных текстовых фрагментов на разных языках
sample_texts <- list(
  Russian = "«Война и мир» — роман-эпопея Льва Николаевича Толстого, описывающий русское общество в эпоху войн против Наполеона.",
  French = "Aujourd'hui, maman est morte. Ou peut-être hier, je ne sais pas. C'est une célèbre citation.",
  Chinese = "学如逆水行舟，不进则退。 这是一个著名的中国谚语，意思是学习就像逆水行舟，不前进就会后退。",
  English_Simple = "This is a simple sentence in English containing only basic ASCII characters.",
  English_Complex = "He said, “That’s a ‘smart’ quote.” This text uses special characters – like an em dash."
)

# 2. Определяем тестовые случаи: язык и соответствующая ему кодировка
test_cases <- data.frame(
  Language = c("Russian", "Russian", "French", "French", "Chinese", "Chinese", "English_Simple", "English_Complex", "English_Complex"),
  TextKey = c("Russian", "Russian", "French", "French", "Chinese", "Chinese", "English_Simple", "English_Complex", "English_Complex"),
  TrueEncoding = c("UTF-8", "windows-1251", "UTF-8", "ISO-8859-1", "UTF-8", "GB18030", "ASCII", "UTF-8", "windows-1252")
)

# Data frame для хранения результатов
results <- data.frame()

# 3. Запускаем цикл по тестовым случаям
for (i in 1:nrow(test_cases)) {
  lang <- test_cases$Language[i]
  text_key <- test_cases$TextKey[i]
  encoding <- test_cases$TrueEncoding[i]
  original_text <- sample_texts[[text_key]]

  # Кодируем текст в нужную кодировку, чтобы получить "сырые" байты
  text_raw <- stri_encode(original_text, from = "UTF-8", to = encoding)

  # --- Тестируем guess_encoding ---
  start_time_guess <- Sys.time()
  guessed <- guess_encoding(text_raw)
  end_time_guess <- Sys.time()
  time_guess <- as.numeric(end_time_guess - start_time_guess)
  
  top_guess <- ifelse(nrow(guessed) > 0, guessed$encoding[1], "None")
  is_guess_correct <- (top_guess == encoding)

  # --- Тестируем repair_encoding ---
  garbled_text <- stri_conv(text_raw, from = encoding, to = "ISO-8859-1")
  
  start_time_repair <- Sys.time()
  repaired_text <- repair_encoding(garbled_text, from = encoding)
  end_time_repair <- Sys.time()
  time_repair <- as.numeric(end_time_repair - start_time_repair)
  
  is_repair_correct <- (repaired_text == original_text)

  # Сохраняем все результаты
  results <- rbind(results, data.frame(
    Language = lang,
    TrueEncoding = encoding,
    GuessedCorrectly = is_guess_correct,
    RepairedCorrectly = is_repair_correct,
    TimeGuess = time_guess,
    TimeRepair = time_repair
  ))
}

# Выводим итоговую таблицу
print("Результаты комплексного эксперимента:")
print(results)


# 4. Визуализация результатов

# График точности угадывания
accuracy_plot <- ggplot(results, aes(x = TrueEncoding, fill = GuessedCorrectly)) +
  geom_bar(stat = "count", position = "dodge") +
  facet_wrap(~ Language, scales = "free_x") +
  labs(
    title = "Точность угадывания кодировки (guess_encoding)",
    x = "Исходная кодировка",
    y = "Количество тестов"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("TRUE" = "green", "FALSE" = "red"))

print(accuracy_plot)

# График скорости выполнения
# Преобразуем данные в "длинный" формат для удобства построения графика
results_long <- tidyr::gather(results, key = "Function", value = "Time", TimeGuess, TimeRepair)

speed_plot <- ggplot(results_long, aes(x = TrueEncoding, y = Time, fill = Function)) +
  geom_col(position = "dodge") +
  facet_wrap(~ Language, scales = "free_x") +
  labs(
    title = "Скорость выполнения функций",
    x = "Исходная кодировка",
    y = "Время (секунды)"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(speed_plot)