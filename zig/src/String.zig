const std = @import("std");
const posix = std.posix;
const print = std.debug.print;

const String = @This();

const STEP = std.heap.pageSize();

slice: []u8,
len: u64,

pub fn init(capacity: ?u64) String {
  const cap: u64 = capacity orelse STEP;

  const ptr = posix.mmap(
    null,
    cap,
    .{.READ = true, .WRITE = true},
    .{.TYPE = .PRIVATE, .ANONYMOUS = true},
    -1,
    0
  ) catch |err| {
    std.process.fatal("Failed to call mmap(): {t}", .{err});
  };

  return (String) {
    .slice = ptr,
    .len = 0,
  };
}

pub fn append(self: *String, char: u8) void {
  if (self.len == self.slice.len) {
    self.slice = posix.mremap(
      @alignCast(self.slice.ptr),
      self.slice.len,
      self.slice.len + STEP,
      .{ .MAYMOVE = true },
      null
    ) catch |err| {
      std.process.fatal("Failed to resize String: {t}", .{err});
    };
  }

  self.slice[self.len] = char;
  self.len += 1;
}

pub fn printSelf(self: *String) void {
  for (0..self.len) |i| {
    print("{c}", .{self.slice[i]});
  }
  print("\n", .{});
}

pub fn clear(self: *String) void {
  self.len = 0;
}
