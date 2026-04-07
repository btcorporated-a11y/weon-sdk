<p align="right">
  <img src="assets/logo.jpg" alt="WeOn SDK Logo" width="100">
</p>

# WeOn SDK v2.0.0-alpha
[![Version](https://img.shields.io/badge/version-2.0.0--alpha-blue)](https://github.com/your-repo)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20windows-lightgrey)]()

[cite_start]**WeOn SDK** — это высокопроизводительное ядро для создания плагинных систем с упором на низкую задержку и строгую стабильность ABI[cite: 9, 20]. [cite_start]Написанное на **Zig**, оно предоставляет разработчикам на C, C++ и Rust безопасный мост для обмена данными без лишнего копирования (Zero-copy)[cite: 1, 77, 91].

---

## 🚀 Основные возможности

* [cite_start]**Zero-Copy архитектура**: Десериализатор строк и сырых данных возвращает прямые указатели в буфер, исключая аллокации[cite: 90, 91, 95].
* [cite_start]**Высокоскоростная шина (Data Bus)**: Система `Shared Request` позволяет множеству плагинов-писателей безопасно отправлять команды одному хосту-читателю (например, рендереру)[cite: 123, 127].
* [cite_start]**Умное управление состоянием**: `Shared State` менеджер с поддержкой Fat Pointers (View) обеспечивает безопасный доступ к памяти с проверкой границ[cite: 12, 112, 116].
* [cite_start]**Строгий порядок байтов**: Все бинарные данные упаковываются в формате **Little Endian** для кросс-платформенной совместимости[cite: 30, 70].
* [cite_start]**Безопасность типов**: Использование хэшей FNV-1a (64-bit) вместо строк в рантайме для мгновенной идентификации ресурсов[cite: 64, 65, 68].

---

## 🏗 Архитектура API

[cite_start]Сердце SDK — структура `weon_api_t`, которая предоставляет доступ к трем слоям управления[cite: 4, 26]:

| Слой | Назначение | Ключевые компоненты |
| :--- | :--- | :--- |
| **Утилиты** | Базовый инструментарий | [cite_start]Логгер (с уровнями), FNV-1a Хэширование [cite: 21, 63, 68] |
| **Ресурсы** | Взаимодействие и память | [cite_start]Shared State (переменные), Shared Request (команды) [cite: 22, 23] |
| **Трансформация** | Бинарная упаковка | [cite_start]Serializer (Writer), Deserializer (Reader) [cite: 24, 25] |

---

## 🛠 Жизненный цикл плагина

WeOn использует контрактную модель. [cite_start]Каждый плагин должен реализовать интерфейс `PluginInterface`[cite: 28]:

1.  [cite_start]**`on_init`**: Получение доступа к глобальному Core API и регистрация команд[cite: 28].
2.  [cite_start]**`on_create`**: Инициализация инстанса плагина в конкретном пространстве имен[cite: 28].
3.  [cite_start]**`on_command`**: Обработка входящих событий через хэши команд[cite: 28].
4.  [cite_start]**`on_destroy`**: Корректное освобождение ресурсов[cite: 28].

---

## 💻 Быстрый старт (C API)

### 1. Инициализация SDK
```c
#include "weon/api.h"

int main() {
    // 1. Инициализируем ядро и аллокаторы
    if (!weon_sdk_init()) return -1; [cite_start]// [cite: 5, 7]

    // 2. Получаем таблицу функций API
    const weon_api_t* api = weon_sdk_get_api(); [cite_start]// [cite: 7, 26]

    // 3. Используем инструменты
    api->log->print(WEON_LOG_INFO, "CORE", "SDK Starter Pack Active!"); [cite_start]// [cite: 21]
    
    return 0;
}
```

### 2. Работа с данными (Serialization)
```c
// Создаем писателя на базе выделенного буфера
weon_writer_t writer = api->serializer->init(my_view); [cite_start]// [cite: 24, 39]
api->serializer->u32(&writer, 42); [cite_start]// [cite: 24, 42]
api->serializer->str(&writer, "Hello", 5); [cite_start]// [cite: 24, 50]

if (writer.has_error) {
    // Обработка переполнения буфера
}
```

---

## 📂 Структура проекта

* **`bin/`**: Готовые артефакты для интеграции.
    * [cite_start]`include/weon/`: Заголовочные файлы C API[cite: 20, 26].
    * `linux-x86_64/`: Динамические библиотеки `.so`.
    * `windows-x86_64/`: Библиотеки `.dll` и отладочные символы `.pdb`.
* **`code/src/`**: Реализация ядра на языке Zig.
    * [cite_start]`core/`: Логика Shared State и Request менеджеров[cite: 98, 123].
    * [cite_start]`ffi/`: Определения ABI и контрактов[cite: 9, 28].
    * [cite_start]`tools/`: Реализация сериализации, хэширования и логов[cite: 29, 55, 64, 70].
* **`tests/`**: Набор тестов на C для проверки стабильности API.

---

## 🔨 Сборка из исходников

### Требования
* **Zig Compiler** (рекомендуется v0.13.0 или выше).

### Команды
**Для Linux:**
```bash
chmod +x build.sh
./build.sh
```

**Для Windows:**
```cmd
build.bat
```

Скрипты автоматически соберут проект, запустят внутренние тесты и обновят содержимое папки `bin/`.