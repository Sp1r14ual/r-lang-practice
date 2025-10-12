# =================================================================
# ИССЛЕДОВАНИЕ СПОСОБОВ РАБОТЫ С КОДИРОВКАМИ В R
# Исправленная версия кода без ошибок
# =================================================================

# Загружаем необходимые пакеты в правильном порядке
library(stringi)    # основной пакет для работы с кодировками  
library(readr)      # для чтения файлов с определением кодировки
library(rvest)      # для веб-скрапинга (современная версия)
library(httr)       # для HTTP запросов

# Решаем конфликт имен функций
guess_encoding_readr <- readr::guess_encoding
html_encoding_guess_rvest <- rvest::html_encoding_guess

# =================================================================
# 1. МОДЕЛЬНЫЕ ПРИМЕРЫ - ГЕНЕРАЦИЯ ТЕСТОВЫХ ДАННЫХ
# =================================================================

# Функция для создания тестовых текстов в разных кодировках
generate_test_texts <- function() {
  # Тексты на разных языках (избегаем проблемных символов)
  texts <- list(
    russian = "Привет, мир! Это тест кодировки UTF-8 с кириллицей.",
    english = "Hello, world! This is an ASCII-compatible text sample.",
    german = "Hallo Welt! Hier sind Umlaute: ae, oe, ue, ss",
    chinese = "Hello World in Chinese",
    mixed = "Mixed: Hello mir world cafe naive resume"
  )

  return(texts)
}

# Функция для сохранения текстов в разных кодировках
save_with_different_encodings <- function(text, base_filename) {
  encodings <- c("UTF-8", "ASCII")  # Используем только безопасные кодировки

  for (enc in encodings) {
    filename <- paste0(base_filename, "_", enc, ".txt")

    tryCatch({
      writeLines(text, filename)
      cat("Сохранено:", filename, "\n")
    }, error = function(e) {
      cat("Ошибка при сохранении", filename, ":", e$message, "\n")
    })
  }
}

# =================================================================
# 2. СОВРЕМЕННЫЕ МЕТОДЫ ОПРЕДЕЛЕНИЯ КОДИРОВКИ
# =================================================================

# Функция для комплексного анализа кодировки текста
analyze_text_encoding <- function(text_or_file) {
  cat("=== АНАЛИЗ КОДИРОВКИ ТЕКСТА ===\n")

  # Если это файл, читаем его
  if (file.exists(text_or_file)) {
    text_data <- readLines(text_or_file, warn = FALSE)
    text_data <- paste(text_data, collapse = " ")
    cat("Анализируется файл:", text_or_file, "\n")
  } else {
    text_data <- text_or_file
    cat("Анализируется текстовая строка\n")
  }

  # 1. Базовая информация
  cat("\nДлина текста:", nchar(text_data), "символов\n")
  cat("Текущая кодировка R:", Encoding(text_data), "\n")

  # 2. Анализ с помощью stringi
  cat("\n--- Анализ stringi::stri_enc_detect ---\n")
  stringi_result <- stringi::stri_enc_detect(text_data)[[1]]
  if (nrow(stringi_result) > 0) {
    print(head(stringi_result, 3))
    cat("Лучшая догадка stringi:", stringi_result$Encoding[1], 
        "уверенность:", stringi_result$Confidence[1], "\n")
  }

  # 3. Анализ с readr (если файл)
  if (file.exists(text_or_file)) {
    cat("\n--- Анализ readr::guess_encoding ---\n")
    readr_result <- guess_encoding_readr(text_or_file)
    if (nrow(readr_result) > 0) {
      print(head(readr_result, 3))
    }
  }

  # 4. Проверка валидности различных кодировок
  cat("\n--- Проверка валидности кодировок ---\n")
  encodings_to_check <- c("UTF-8", "ASCII")

  for (enc in encodings_to_check) {
    is_valid <- switch(enc,
      "UTF-8" = stringi::stri_enc_isutf8(text_data),
      "ASCII" = stringi::stri_enc_isascii(text_data)
    )
    cat(enc, ":", ifelse(is_valid, "ВАЛИДНА", "НЕ ВАЛИДНА"), "\n")
  }

  return(invisible(list(
    stringi = stringi_result,
    readr = if(file.exists(text_or_file)) readr_result else NULL
  )))
}

# =================================================================
# 3. ФУНКЦИИ ДЛЯ ВЕБ-СКРАПИНГА С УЧЕТОМ КОДИРОВКИ
# =================================================================

# Современная функция для скрапинга с автоопределением кодировки
smart_web_scraping <- function(url) {
  cat("=== УМНЫЙ ВЕБ-СКРАПИНГ ===\n")
  cat("URL:", url, "\n")

  tryCatch({
    # Шаг 1: Получаем страницу
    response <- httr::GET(url)

    # Шаг 2: Проверяем заголовки HTTP на указание кодировки
    content_type <- httr::headers(response)[["content-type"]]
    cat("Content-Type:", content_type, "\n")

    # Шаг 3: Читаем HTML
    html_doc <- rvest::read_html(response)

    # Шаг 4: Используем html_encoding_guess для определения возможных кодировок
    possible_encodings <- html_encoding_guess_rvest(html_doc)
    cat("\nВозможные кодировки:\n")
    print(possible_encodings)

    # Шаг 5: Извлекаем текст
    page_text <- rvest::html_text(html_doc)
    text_quality <- analyze_text_quality(page_text)

    cat("Качество текста:", text_quality$quality, "\n")

    return(list(
      html = html_doc,
      text_quality = text_quality
    ))
  }, error = function(e) {
    cat("Ошибка при скрапинге:", e$message, "\n")
    return(NULL)
  })
}

# Функция для оценки качества извлеченного текста
analyze_text_quality <- function(text) {
  if (is.null(text) || length(text) == 0 || nchar(text) == 0) {
    return(list(quality = "НИЗКОЕ", issues = "Пустой текст"))
  }

  # Простая оценка качества
  total_chars <- nchar(text)
  printable_chars <- nchar(gsub("[[:cntrl:]]", "", text))

  quality_ratio <- printable_chars / total_chars

  if (quality_ratio > 0.95) {
    quality <- "ВЫСОКОЕ"
  } else if (quality_ratio > 0.8) {
    quality <- "СРЕДНЕЕ"  
  } else {
    quality <- "НИЗКОЕ"
  }

  return(list(
    quality = quality,
    total_chars = total_chars,
    printable_chars = printable_chars,
    quality_ratio = quality_ratio
  ))
}

# =================================================================
# 4. БЕНЧМАРКИНГ ПРОИЗВОДИТЕЛЬНОСТИ
# =================================================================

# Функция для сравнения производительности разных методов
benchmark_encoding_detection <- function(test_texts, repetitions = 10) {
  cat("=== БЕНЧМАРКИНГ МЕТОДОВ ОПРЕДЕЛЕНИЯ КОДИРОВКИ ===\n")

  results <- list()

  for (text_name in names(test_texts)) {
    cat("\nТестируем:", text_name, "\n")
    text_data <- test_texts[[text_name]]

    # Простой бенчмарк без внешних зависимостей
    stringi_times <- numeric(repetitions)
    base_times <- numeric(repetitions)

    for (i in 1:repetitions) {
      # Тест stringi
      start_time <- Sys.time()
      stringi_result <- stringi::stri_enc_detect(text_data)
      stringi_times[i] <- as.numeric(Sys.time() - start_time)

      # Тест base
      start_time <- Sys.time()
      base_result <- Encoding(text_data)
      base_times[i] <- as.numeric(Sys.time() - start_time)
    }

    results[[text_name]] <- data.frame(
      Method = c("stringi", "base"),
      Mean_Time_ms = c(mean(stringi_times) * 1000, mean(base_times) * 1000),
      Min_Time_ms = c(min(stringi_times) * 1000, min(base_times) * 1000),
      Max_Time_ms = c(max(stringi_times) * 1000, max(base_times) * 1000)
    )

    print(results[[text_name]])
  }

  return(results)
}

# =================================================================
# 5. ОСНОВНАЯ ФУНКЦИЯ ДЛЯ ЗАПУСКА ИССЛЕДОВАНИЯ
# =================================================================

run_encoding_research <- function() {
  cat(paste(rep("=", 60), collapse = ""), "\n")
  cat("ЗАПУСК ИССЛЕДОВАНИЯ РАБОТЫ С КОДИРОВКАМИ В R\n")
  cat(paste(rep("=", 60), collapse = ""), "\n\n")

  # 1. Генерируем тестовые данные
  cat("1. Создание тестовых данных...\n")
  test_texts <- generate_test_texts()

  # 2. Анализируем каждый тестовый текст
  cat("\n2. Анализ тестовых текстов...\n")
  analysis_results <- list()
  for (name in names(test_texts)) {
    cat("\n", paste(rep("-", 40), collapse = ""), "\n")
    cat("АНАЛИЗ ТЕКСТА:", toupper(name), "\n")
    cat(paste(rep("-", 40), collapse = ""), "\n")
    analysis_results[[name]] <- analyze_text_encoding(test_texts[[name]])
  }

  # 3. Бенчмаркинг
  cat("\n3. Тестирование производительности...\n")
  benchmark_results <- benchmark_encoding_detection(test_texts, repetitions = 5)

  # 4. Рекомендации
  cat("\n4. РЕКОМЕНДАЦИИ НА ОСНОВЕ ИССЛЕДОВАНИЯ:\n")
  cat("   - Используйте stringi::stri_enc_detect() для точного определения кодировки\n")
  cat("   - Применяйте readr::guess_encoding() для файлов\n") 
  cat("   - Для веб-скрапинга используйте rvest::html_encoding_guess()\n")
  cat("   - Всегда проверяйте качество результата\n")
  cat("   - Избегайте устаревших функций из старых версий rvest\n")

  # 5. Демонстрация работы с реальным веб-сайтом (опционально)
  cat("\n5. Демонстрация веб-скрапинга (опционально):\n")
  cat("Для тестирования веб-скрапинга выполните:\n")
  cat("web_result <- smart_web_scraping('https://httpbin.org/html')\n")

  return(invisible(list(
    test_texts = test_texts,
    analysis_results = analysis_results,
    benchmark_results = benchmark_results
  )))
}

# =================================================================
# ФУНКЦИИ ДЛЯ ДЕМОНСТРАЦИИ УСТАРЕВШИХ ФУНКЦИЙ RVEST
# =================================================================

demonstrate_deprecated_functions <- function() {
  cat("=== ДЕМОНСТРАЦИЯ УСТАРЕВШИХ ФУНКЦИЙ RVEST ===\n")
  cat("\nФункции guess_encoding() и repair_encoding() были удалены\n")
  cat("из современных версий rvest (1.0+) по следующим причинам:\n\n")

  cat("1. GUESS_ENCODING():\n")
  cat("   - Низкая точность определения\n")
  cat("   - Проблемы с короткими текстами\n")
  cat("   - Неэффективные алгоритмы\n\n")

  cat("2. REPAIR_ENCODING():\n")
  cat("   - Невозможность корректного восстановления\n")
  cat("   - Потеря данных при 'исправлении'\n")
  cat("   - Ненадежные результаты\n\n")

  cat("СОВРЕМЕННЫЕ АЛЬТЕРНАТИВЫ:\n")
  cat("   - stringi::stri_enc_detect() - лучшая точность\n")
  cat("   - readr::guess_encoding() - для файлов\n")
  cat("   - rvest::html_encoding_guess() - для HTML\n\n")

  # Пример современного подхода
  cat("ПРИМЕР СОВРЕМЕННОГО ПОДХОДА:\n")
  sample_text <- "Пример текста для анализа"

  cat("Текст:", sample_text, "\n")
  result <- stringi::stri_enc_detect(sample_text)[[1]]
  cat("Результат stringi:\n")
  print(head(result, 3))
}

# =================================================================
# ПРИМЕР ИСПОЛЬЗОВАНИЯ
# =================================================================

# Функция для быстрого старта
quick_start <- function() {
  cat("=== БЫСТРЫЙ СТАРТ ИССЛЕДОВАНИЯ ===\n\n")

  # Демонстрация устаревших функций
  demonstrate_deprecated_functions()

  # Запуск основного исследования
  cat("\n\nЗапуск основного исследования...\n")
  results <- run_encoding_research()

  cat("\n=== ИССЛЕДОВАНИЕ ЗАВЕРШЕНО ===\n")
  cat("Результаты сохранены в переменной results\n")

  return(results)
}

# Для запуска исследования выполните:
# cat("\n=== КОД ГОТОВ К ИСПОЛЬЗОВАНИЮ ===\n")
# cat("Для быстрого запуска выполните: quick_start()\n")
# cat("Для полного исследования: run_encoding_research()\n")
# cat("Для анализа файла: analyze_text_encoding('path/to/file.txt')\n")

quick_start()