const std = @import("std");
const Io = std.Io;
const print = std.debug.print;
const log = std.log;
const posix = std.posix;

const String = @import("String.zig");

const TokenizerState = enum {
  comment,
  command,
  command_between,
  redirection,
};

pub fn main(init: std.process.Init) !void {
  const arena = init.arena.allocator();

  // Accessing command line arguments:
  const args = try init.minimal.args.toSlice(arena);
  if (args.len < 2) {
    std.process.fatal("Please provide a script to execute", .{});
  }

  // In order to do I/O operations need an `Io` instance.
  const io = init.io;
  const script_file: Io.File = Io.Dir.cwd().openFile(io, args[1], .{}) catch |err| {
    std.process.fatal("{t}", .{err});
  };

  var script_buf: [1]u8 = undefined;
  var script_reader: Io.File.Reader = .init(script_file, io, &script_buf);
  const script = &script_reader.interface;

  // var stdout_buf: [100]u8 = undefined;
  // var stdout_writer: Io.File.Writer = .init(Io.File.stdout(), io, &stdout_buf);
  // const stdout = &stdout_writer.interface;

  var tokenizer_state: TokenizerState = .command;
  var statement = try std.ArrayList(u8).initCapacity(arena, 100);
  var redirection = try std.ArrayList(u8).initCapacity(arena, 100);

  nextByte: while (script.takeByte()) |char| {
    // If we're inside a comment, skip all characters until we reach a newline.
    if (tokenizer_state == .comment) {
      if (char == '\n') {
        tokenizer_state = .command;
      }
      continue :nextByte;
    }

    tokenizer_state = state: switch (char) {
      ' ', '\t', '\n' => {
        if (tokenizer_state == .command) {
          try statement.append(arena, char);
        }
        break :state tokenizer_state;
      },
      '#' => .comment,
      '>' => .redirection,
      ';', '|' => {
        // Run it!
        // print("Statement: ", .{});
        // for (statement.items) |item| {
        //   print("{c}", .{item});
        // }
        // print("\n", .{});
        // print("Redirection: ", .{});
        // for (redirection.items) |item| {
        //   print("{c}", .{item});
        // }
        // print("\n\n", .{});

        var parsed: std.ArrayList([]const u8) = try .initCapacity(arena, 10);
        var last_space_idx: usize = 0;
        for (statement.items, 0..) |s, i| {
          if (s == ' ') {
            try parsed.append(arena, statement.items[last_space_idx..i]);
            last_space_idx = i + 1;
          }
          if (i == statement.items.len - 1 and parsed.items.len == 0) {
            try parsed.append(arena, statement.items);
          }
        }

        for (parsed.items) |p| {
          print("'", .{});
          for (p) |c| {
            print("{c}", .{c});
          }
          print("' ", .{});
        }
        print("\n", .{});

        // split up the Statement based on whitespace
//         std.process.spawn(io, .{
//
//         });

        // pass the args to some equivalent of execvp() (without replacing the process)
        //
        // stream stdout to the screen if no redirection
        // if redirection, send it there


        // Reset back to initial state to start parsing the next statement
        statement.clearRetainingCapacity();
        redirection.clearRetainingCapacity();
        break :state .command_between;
      },
      else => {
        if (tokenizer_state == .command or tokenizer_state == .command_between) {
          try statement.append(arena, char);
        } else if (tokenizer_state == .redirection) {
          try redirection.append(arena, char);
        }
        break :state tokenizer_state;
      },
    };

    // print("{c}: {}\n", .{char, tokenizer_state});
  } else |err| switch (err) {
    error.EndOfStream => log.info("Finished running script.", .{}),
    else => return err,
  }
}
