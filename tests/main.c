#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <string.h>

#include "weon/api.h"

// Типы функций из экспорта ядра
typedef bool (*weon_init_fn)();
typedef const struct weon_api_t* (*weon_get_api_fn)();
typedef void (*weon_shutdown_fn)();

int main() {
    const char* lib_path = "./bin/linux-x86_64/weon-sdk.so";
    void* handle = dlopen(lib_path, RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "❌ FATAL: Cannot load %s\n", lib_path);
        return 1;
    }

    weon_init_fn weon_sdk_init = (weon_init_fn)dlsym(handle, "weon_sdk_init");
    weon_get_api_fn weon_sdk_get_api = (weon_get_api_fn)dlsym(handle, "weon_sdk_get_api");
    weon_shutdown_fn weon_sdk_shutdown = (weon_shutdown_fn)dlsym(handle, "weon_sdk_shutdown");

    if (!weon_sdk_init || !weon_sdk_get_api) return 1;

    // 1. Инициализация
    if (!weon_sdk_init()) {
        fprintf(stderr, "❌ TEST FAILED: SDK Initialization\n");
        return 2;
    }
    const struct weon_api_t* api = weon_sdk_get_api();
    api->log->print(WEON_LOG_INFO, "TEST", "--- Starting WeOn SDK Release Validation ---");

    // 2. Тест: Shared State + Serializer + Deserializer
    weon_state_req_t s_req = { .namespace_id = 0xA, .state_alias = 0xB, .requestor_id = 0xC };
    const char* test_msg = "Release_Candidate_2.0";
    uint32_t msg_len = (uint32_t)strlen(test_msg);

    weon_view_t view = api->state->create_var(&s_req, 128);
    if (view.data == NULL) return 4;

    weon_writer_t writer = api->serializer->init(view);
    api->serializer->str(&writer, (const uint8_t*)test_msg, msg_len);
    if (writer.has_error) return 3;

    weon_const_view_t c_view = api->state->read_var(&s_req);
    weon_reader_t reader = api->deserializer->init(c_view);
    uint32_t out_len = 0;
    const char* decoded = (const char*)api->deserializer->str(&reader, &out_len);

    if (!decoded || strncmp(test_msg, decoded, out_len) != 0) {
        fprintf(stderr, "❌ TEST FAILED: State/Serialization Integrity\n");
        return 4;
    }

    // 3. Тест: Shared Request (Data Bus)
    weon_buffer_req_t b_req = { .namespace_id = 0x1, .buffer_alias = 0x2, .requestor_id = 0x3 };
    weon_buffer_handle_t buf_h = api->request->create_buffer(&b_req, 1024);
    if (!buf_h) {
        fprintf(stderr, "❌ TEST FAILED: Request Buffer Creation\n");
        return 5;
    }

    // Резервируем место под фиктивную команду (Hash 0xEE, данные 16 байт)
    weon_view_t cmd_v = api->request->reserve_space(buf_h, 0xEE, 16);
    if (cmd_v.data == NULL) {
        fprintf(stderr, "❌ TEST FAILED: Buffer Space Reservation\n");
        return 5;
    }

    // Проверяем чтение буфера
    weon_buffer_view_t b_view = api->request->read_buffer(buf_h);
    if (b_view.command_count != 1) {
        fprintf(stderr, "❌ TEST FAILED: Request Readback\n");
        return 5;
    }

    // 4. Финализация
    api->log->print(WEON_LOG_INFO, "TEST", "--- All Systems Green. Ready for Release! ---");
    if (weon_sdk_shutdown) weon_sdk_shutdown();
    dlclose(handle);

    printf("✅ SDK VALIDATED: 0 errors\n");
    return 0; 
}