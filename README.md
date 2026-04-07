<div align="center">

# WeOn SDK
**The High-Performance Core for Next-Gen Plugin Systems**

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version: 2.0.0-alpha](https://img.shields.io/badge/Version-2.0.0--alpha-blue)
![Platform: Linux | Windows | macOS](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey)
![Language: Zig](https://img.shields.io/badge/Language-Zig-orange)
[![WeOn SDK CI](https://github.com/btcorporated-a11y/weon-sdk/actions/workflows/pipeline.yml/badge.svg)](https://github.com/btcorporated-a11y/weon-sdk/actions/workflows/pipeline.yml)

---
</div>

<table border="0">
  <tr>
    <td width="75%" valign="top">
      <h3>System Overview</h3>
      <p>
        <b>WeOn SDK</b> is a high-performance core designed for developing modular plugin systems with a focus on ultra-low latency and ABI stability. Written in <b>Zig</b>, it provides C/C++, and Rust developers with a powerful interface for direct memory interaction, leveraging <b>Zero-Copy</b> principles to eliminate data transfer overhead.
      </p>
      <p>
        <i>Current Status: <b>v2.0.0-alpha</b> — Ready for early-stage integration and performance profiling.</i>
      </p>
    </td>
    <td width="25%" align="center" valign="middle">
      <img src="assets/logo.jpg" alt="WeOn SDK Logo" width="180">
    </td>
  </tr>
</table>

---
<details>
<summary>🏗️ <b>Architecture & Core Principles</b> (Click to expand)</summary>

### True Zero-Copy
Unlike traditional SDKs that copy data between various buffers, WeOn provides plugins with direct access to the core's system memory.



```mermaid
graph TD
    subgraph Standard_Approach [Legacy SDK - Slow]
        A[Plugin A] -- "Copy Data" --> B[Intermediate Buffer]
        B -- "Copy Data" --> C[Core]
        C -- "Copy Data" --> D[Plugin B]
        style Standard_Approach fill:#2D572C,stroke:#ff0000
    end

    subgraph WeOn_Approach [WeOn SDK - Zero-Copy]
        CoreMemory[(Global Shared Memory)]
        PA[Plugin A] -- "Direct Access (View)" --> CoreMemory
        PB[Plugin B] -- "Direct Access (ConstView)" --> CoreMemory
        style WeOn_Approach fill: #252850,stroke:#00aa00
    end
```

### Memory Ownership Management
The Core acts as an arbiter: it allocates physical RAM blocks and provides plugins with **Fat Pointers** via `View` structures.

```mermaid
sequenceDiagram
    participant P as Plugin
    participant C as SDK Core
    participant RAM as System RAM

    P->>C: create_var(size: 1024)
    C->>RAM: Allocate block
    C-->>P: View { data_ptr, size }
    Note right of P: Plugin writes directly to RAM <br/> at the provided address
    
    P->>C: update_var()
    C-->>P: View (Same address)
    
    Note over P, RAM: Zero intermediate allocations!
    
    P->>C: destroy_var()
    C->>RAM: Free block
    Note right of P: Pointer becomes invalid
```
</details>

---

<details>
<summary>🛠️ <b>Core Modules</b> (Click to expand)</summary>

### 1. Shared State (Variable Manager)
Enables plugins to create variables in a global namespace accessible to other modules for reading. Security is maintained via `owner_id` validation: only the creator can modify or delete their specific data.

```mermaid
graph TD
    classDef default fill:#2d2d2d,stroke:#555,color:#eeeeee;
    classDef core fill:#1a1a1a,stroke:#8833ff,stroke-width:2px,color:#ffffff;
    classDef logic fill:#333333,stroke:#00e5ff,color:#00e5ff;

    subgraph Plugin_Space [Plugin Context]
        Data[Native C Struct / Variables]
    end

    subgraph Core_Memory [SDK Core: Shared State]
        Buffer[("Allocated RAM Buffer<br/>(Physical Address)")]
    end

    Data -->|1. Request Allocation| CreateVar[api->state->create_var]
    CreateVar -->|2. Returns Mutable View| View["weon_view_t {data, size}"]
    View -->|3. Wrap into Cursor| InitWriter[api->serializer->init]
    InitWriter -->|4. Active Writer| Writer(weon_writer_t)
    Writer -->|5. Direct Write| Buffer

    Buffer -.->|6. Request Write Access| UpdateVar[api->state->update_var]
    UpdateVar -.->|7. Returns Mutable View| View 

    Buffer -->|8. Request Access| ReadVar[api->state->read_var]
    ReadVar -->|9. Returns Const View| CView[weon_const_view_t]
    CView -->|10. Wrap into Cursor| InitReader[api->deserializer->init]
    InitReader -->|11. Active Reader| Reader(weon_reader_t)
    Reader -->|12. Zero-Copy Extraction| Result[Decoded Data / Pointers]

    class Buffer core;
    class CreateVar,UpdateVar,ReadVar logic;
```

### 2. Data Bus (Shared Request)
A high-speed command bus designed for streaming command buffers. It implements a **Multi-Writer / Single-Reader** architecture.

* **Reserve Space**: Plugins request space for a single command; the core atomically shifts an internal cursor.
* **Batch Read**: The Host (e.g., a Renderer) consumes all accumulated commands in a single efficient call.

```mermaid
graph TD
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

    Create -->|1. Allocate Capacity| Buffer
    Buffer -->|2. Return Ticket| Handle

    P1 & P2 & P3 -->|3. Get Ticket| Handle
    Handle -->|4. reserve_space| Cursor
    Cursor -->|5. Shift & Return Offset| P1 & P2 & P3
    P1 & P2 & P3 -->|6. Direct Memory Write| Buffer

    Buffer -->|7. Batch Read| Read
    Read -->|8. Process All Cmds| Clear
    Clear -->|9. Reset Cursor to 0| Cursor

    class Create,Read,Clear host;
    class P1,P2,P3 client;
    class Buffer memory;
```
</details>

---

<details>
<summary>📦 <b>Project Structure</b> (Click to expand)</summary>

```text
.
├── bin/                 # Build artifacts (headers, .so, .dll, .lib)
├── code/                # Core engine source code (Zig)
│   ├── include/weon/    # Public C Headers
│   └── src/             # Implementation logic
├── scripts/             # Build and installation scripts (Linux/Windows)
└── tests/               # Integration test suite (C)
```
</details>

---

<details>
<summary>🚀 <b>Quick Start</b> (Click to expand)</summary>

### Prerequisites
* **Zig Compiler** (v0.13.0 or higher).
* **GCC/Clang** (for running tests).

### Build & Install (Linux)
```bash
chmod +x build.sh
./build.sh
```
The script will automatically:
1. Clean previous build artifacts.
2. Compile the SDK for both Linux and Windows (cross-compilation).
3. Execute integration tests to verify data integrity.
4. Install the SDK to system paths (e.g., `/usr/local/lib/weon`).

### C Usage Example
```c
#include <weon/api.h>

int main() {
    if (weon_sdk_init()) { 
        const weon_api_t* api = weon_sdk_get_api(); 
        api->log->print(WEON_LOG_INFO, "APP", "WeOn SDK Ready!"); 
    }
    return 0;
}
```
</details>

---

## 📄 License
This project is released under the **MIT License**. See the [LICENSE] file for full details.