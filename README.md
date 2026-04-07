<p align="right">
  <img src="assets/logo.jpg" alt="WeOn SDK Logo" width="100">
</p>

# WeOn SDK v2.0.0-alpha

[cite_start]**WeOn SDK** — это высокопроизводительное ядро для разработки плагинных систем с упором на минимальные задержки и стабильность ABI[cite: 10]. [cite_start]Написанное на языке **Zig**, оно предоставляет разработчикам на C/C++ и Rust интерфейс для прямого взаимодействия с памятью без лишних затрат на копирование данных (Zero-Copy)[cite: 10, 11].

---

## 🏗️ Архитектура и принципы работы

### Истинный Zero-Copy
[cite_start]В отличие от традиционных SDK, которые копируют данные между буферами, WeOn предоставляет плагинам прямой доступ к системной памяти ядра[cite: 7].

```mermaid
graph TD
    subgraph Standard_Approach [Обычный SDK Медленно]
        A[Plugin A] -- "Copy Data" --> B[Intermediate Buffer]
        B -- "Copy Data" --> C[Core]
        C -- "Copy Data" --> D[Plugin B]
        style Standard_Approach fill:#2D572C,stroke:#ff0000
    end

    subgraph WeOn_Approach [WeOn SDK Zero-Copy]
        CoreMemory[(Global Shared Memory)]
        PA[Plugin A] -- "Direct Access (View)" --> CoreMemory
        PB[Plugin B] -- "Direct Access (ConstView)" --> CoreMemory
        style WeOn_Approach fill: #252850,stroke:#00aa00
    end
```

### Управление владением памятью
[cite_start]Ядро выступает в роли арбитра: оно выделяет физические блоки RAM и передает плагинам "толстые указатели" (Fat Pointers) в виде структур `View`[cite: 6, 7].

```mermaid
sequenceDiagram
    participant P as Plugin
    participant C as SDK Core
    participant RAM as System RAM

    P->>C: create_var(size: 1024)
    C->>RAM: Allocate block
    C-->>P: View { data_ptr, size }
    Note right of P: Плагин пишет напрямую в RAM <br/> по выданному адресу
    
    P->>C: update_var()
    C-->>P: View (Тот же адрес)
    
    Note over P, RAM: Никаких промежуточных аллокаций!
    
    P->>C: destroy_var()
    C->>RAM: Free block
    Note right of P: Указатель становится невалидным
```

---

## 🛠️ Основные модули

### 1. Shared State (Менеджер состояний)
[cite_start]Позволяет плагинам создавать переменные в общем пространстве имен, доступные другим модулям для чтения[cite: 7]. [cite_start]Безопасность обеспечивается проверкой `owner_id`: только создатель может изменять или удалять свои данные[cite: 16].

```mermaid
graph TD
    %% Общие стили для темной темы
    classDef default fill:#2d2d2d,stroke:#555,color:#eeeeee;
    classDef core fill:#1a1a1a,stroke:#8833ff,stroke-width:2px,color:#ffffff;
    classDef logic fill:#333333,stroke:#00e5ff,color:#00e5ff;

    subgraph Plugin_Space [Plugin Context]
        Data[Native C Struct / Variables]
    end

    subgraph Core_Memory [SDK Core: Shared State]
        Buffer[("Allocated RAM Buffer<br/>(Physical Address)")]
    end

    %% --- WRITING / CREATION ---
    Data -->|1. Request Allocation| CreateVar[api->state->create_var]
    CreateVar -->|2. Returns Mutable View| View["weon_view_t {data, size}"]
    View -->|3. Wrap into Cursor| InitWriter[api->serializer->init]
    InitWriter -->|4. Active Writer| Writer(weon_writer_t)
    Writer -->|5. Direct Write| Buffer

    %% --- UPDATING ---
    Buffer -.->|6. Request Write Access| UpdateVar[api->state->update_var]
    UpdateVar -.->|7. Returns Mutable View| View 

    %% --- READING ---
    Buffer -->|8. Request Access| ReadVar[api->state->read_var]
    ReadVar -->|9. Returns Const View| CView[weon_const_view_t]
    CView -->|10. Wrap into Cursor| InitReader[api->deserializer->init]
    InitReader -->|11. Active Reader| Reader(weon_reader_t)
    Reader -->|12. Zero-Copy Extraction| Result[Decoded Data / Pointers]

    %% Стилизация
    class Buffer core;
    class CreateVar,UpdateVar,ReadVar logic;
    
    style Buffer fill:#4a148c,stroke:#ce93d8,color:#ffffff
    style View fill:#004d40,stroke:#4db6ac,color:#80cbc4
    style CView fill:#4e342e,stroke:#bcaaa4,color:#d7ccc8
    style Plugin_Space fill:#212121,color:#ffffff
    style Core_Memory fill:#212121,color:#ffffff
```

### 2. Data Bus (Shared Request)
[cite_start]Высокоскоростная шина для передачи потоков команд[cite: 8]. [cite_start]Реализует архитектуру "Много писателей — Один читатель"[cite: 8].

* [cite_start]**Reserve Space**: Плагины запрашивают место под одну команду, ядро атомарно сдвигает внутренний курсор[cite: 8, 17].
* [cite_start]**Batch Read**: Хост (например, рендерер) считывает все накопленные команды за один вызов[cite: 8, 17].

```mermaid
graph TD
    %% Общие стили
    classDef default fill:#2d2d2d,stroke:#555,color:#eeeeee;
    classDef host fill:#1a1a1a,stroke:#00e5ff,stroke-width:2px,color:#ffffff;
    classDef client fill:#1a1a1a,stroke:#ccff00,stroke-width:2px,color:#ffffff;
    classDef memory fill:#4a148c,stroke:#ce93d8,color:#ffffff;

    subgraph Host_Space [Host / Renderer]
        Create[api->request->create_buffer]
        Read[api->request->read_buffer]
        Clear[api->request->clear_buffer]
    end

    subgraph Core_Bus [SDK Core: Command Buffer]
        Handle["Buffer Handle (The Ticket)"]
        Buffer[("Ring-like Buffer RAM<br/>(Physical Address)")]
        Cursor["Internal Cursor<br/>(Atomic Shift)"]
    end

    subgraph Clients [Plugins / Writers]
        P1[Plugin A]
        P2[Plugin B]
        P3[Plugin C]
    end

    %% Flow: Creation
    Create -->|1. Allocate Capacity| Buffer
    Buffer -->|2. Return Ticket| Handle

    %% Flow: Writing
    P1 & P2 & P3 -->|3. Get Ticket| Handle
    Handle -->|4. reserve_space| Cursor
    Cursor -->|5. Shift & Return Offset| P1 & P2 & P3
    P1 & P2 & P3 -->|6. Direct Memory Write| Buffer

    %% Flow: Consumption
    Buffer -->|7. Batch Read| Read
    Read -->|8. Process All Cmds| Clear
    Clear -->|9. Reset Cursor to 0| Cursor

    %% Стилизация
    class Create,Read,Clear host;
    class P1,P2,P3 client;
    class Buffer memory;
    
    style Host_Space fill:#121212,color:#00e5ff,stroke:#00e5ff
    style Clients fill:#121212,color:#ccff00,stroke:#ccff00
    style Core_Bus fill:#1a1a1a,color:#ffffff,stroke:#8833ff
```

---

## 📦 Структура проекта

```text
.
[cite_start]├── bin/                 # Готовые артефакты (headers, .so, .dll, .lib) [cite: 1]
[cite_start]├── code/                # Исходный код ядра на Zig [cite: 1, 11]
[cite_start]│   ├── include/weon/    # Публичные C-заголовки [cite: 10]
[cite_start]│   └── src/             # Реализация логики [cite: 11]
├── scripts/             # Скрипты сборки и установки для Linux/Windows
[cite_start]└── tests/               # Набор интеграционных тестов на C [cite: 12]
```

---

## 🚀 Быстрый старт

### Требования
* **Zig Compiler** (v0.13.0 или выше).
* **GCC/Clang** (для запуска тестов).

### Сборка и установка (Linux)
```bash
chmod +x build.sh
./build.sh
```
Скрипт автоматически:
1. [cite_start]Очистит старые сборки[cite: 13].
2. [cite_start]Скомпилирует SDK под Linux и Windows[cite: 13].
3. [cite_start]Запустит интеграционные тесты для проверки целостности данных[cite: 13].
4. [cite_start]Установит SDK в системные пути (`/usr/local/lib/weon`)[cite: 13].

### Использование в C
```c
#include <weon/api.h>

int main() {
    [cite_start]if (weon_sdk_init()) { // [cite: 11]
        const weon_api_t* api = weon_sdk_get_api(); [cite_start]// [cite: 11]
        api->log->print(WEON_LOG_INFO, "APP", "WeOn SDK Ready!"); [cite_start]// [cite: 11, 14]
    }
    return 0;
}
```

---

## 📄 Лицензия
Проект распространяется под лицензией **MIT**. Подробности в файле [LICENSE].