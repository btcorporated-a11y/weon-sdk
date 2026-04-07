//
// * @file hash.zig
// * @brief High-performance FNV-1a Hashing Implementation
// * @copyright Copyright (c) 2026 WeOn SDK
//

const std = @import("std");
const abi = @import("abi");

const FNV_OFFSET_BASIS: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

pub fn fnv1a_64(data: []const u8) u64 {
var hash_val: u64 = FNV_OFFSET_BASIS;
for (data) |byte| {
hash_val ^= byte;
hash_val *%= FNV_PRIME;
}
return hash_val;
}

fn ffi_fnv1a_64(c_str: [*:0]const u8) callconv(.c) abi.Hash {
const span = std.mem.span(c_str);
return fnv1a_64(span);
}

pub const api_instance = abi.HashApi{
.fnv1a_64 = ffi_fnv1a_64,
};