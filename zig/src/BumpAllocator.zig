const std = @import("std");

const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

pub const bump_allocator: Allocator = .{
  .ptr = undefined,
  .vtable = .{
    .alloc = alloc,
    .resize = resize,
    .remap = remap,
    .free = free,
  }
};

/// Return a pointer to `len` bytes with specified `alignment`, or return
/// `null` indicating the allocation failed.
///
/// `new_len` must be greater than zero.
///
/// `ret_addr` is optionally provided as the first return address of the
/// allocation call stack. If the value is `0` it means no return address
/// has been provided.
fn alloc(context: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {

}

/// Attempt to expand or shrink memory in place.
///
/// `memory.len` must equal the length requested from the most recent
/// successful call to `alloc`, `resize`, or `remap`. `alignment` must
/// equal the same value that was passed as the `alignment` parameter to
/// the original `alloc` call.
///
/// A result of `true` indicates the resize was successful and the
/// allocation now has the same address but a size of `new_len`. `false`
/// indicates the resize could not be completed without moving the
/// allocation to a different address.
///
/// `new_len` must be greater than zero.
///
/// `ret_addr` is optionally provided as the first return address of the
/// allocation call stack. If the value is `0` it means no return address
/// has been provided.
fn resize(context: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {

}

/// Attempt to expand or shrink memory, allowing relocation.
///
/// `memory.len` must equal the length requested from the most recent
/// successful call to `alloc`, `resize`, or `remap`. `alignment` must
/// equal the same value that was passed as the `alignment` parameter to
/// the original `alloc` call.
///
/// A non-`null` return value indicates the resize was successful. The
/// allocation may have same address, or may have been relocated. In either
/// case, the allocation now has size of `new_len`. A `null` return value
/// indicates that the resize would be equivalent to allocating new memory,
/// copying the bytes from the old memory, and then freeing the old memory.
/// In such case, it is more efficient for the caller to perform the copy.
///
/// `new_len` must be greater than zero.
///
/// `ret_addr` is optionally provided as the first return address of the
/// allocation call stack. If the value is `0` it means no return address
/// has been provided.
fn remap(context: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {

}

/// Free and invalidate a region of memory.
///
/// `memory.len` must equal the length requested from the most recent
/// successful call to `alloc`, `resize`, or `remap`. `alignment` must
/// equal the same value that was passed as the `alignment` parameter to
/// the original `alloc` call.
///
/// `ret_addr` is optionally provided as the first return address of the
/// allocation call stack. If the value is `0` it means no return address
/// has been provided.
fn free(context: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize) void {

}
