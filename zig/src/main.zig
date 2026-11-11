const std = @import("std");
const Io = std.Io;
const print = std.debug.print;
const log = std.log;
const posix = std.posix;
const ArrayList = std.ArrayList;

const String = @import("String.zig");

const TokenizerState = enum {
  start,

  comment,

  string,

  interpol_start,
  interpol_variable,
  interpol_subcommand,
  interpol_end,

  redirect_start,
  redirect_file,
  redirect_variable,

  end,

  // TODO:
  // multiline string '\\'
};

const RedirectionType = enum {
  none,
  file,
  variable
};

const Interpolation = union(enum) {
  variable: ArrayList(u8),
  subcommand: CommandSegmentList,
};

const CommandSegment = union(enum) {
  string: ArrayList(u8),
  interpol: Interpolation,
};

const CommandSegmentList = struct {
  list: ArrayList(CommandSegment),
  redirect_type: RedirectionType,
  redirect_name: ArrayList(u8),
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

  var tokenizer_state: TokenizerState = .start;
  // var statement = try std.ArrayList(u8).initCapacity(arena, 100);
  // var redirection = try std.ArrayList(u8).initCapacity(arena, 100);

  while (script.takeByte()) |char| {

    // If we're inside a comment, skip all chars until we reach a newline.
    if (tokenizer_state == .comment) {
      if (char == '\n') {
        tokenizer_state = .start;
      }
      continue;
    }

    tokenizer_state = switch (char) {
      '#' => .comment,

      // Interpolations start with a left curly.
      // If it's immediately followed by a '$', then it's considered a variable.
      // If it's any other character, it's considered a subcommand (see else prong).
      '{' => .interpol_start,
      '$' => switch (tokenizer_state) {
        .interpol_start => .interpol_variable,
        .redirect_start => .redirect_variable,
        else => .string
      },
      '}' => .interpol_end,

      // Anytime we see this, it means a redirect is starting.
      // Anything after this is considered part of the redirection (which can include an interpolation)
      '>' => .redirect_start,

      // Whitespace handling:
      // Any whitespace should be effectively ignored, allowing flexible formatting of scripts.
      // This makes it easy to add newlines and indentations around special characters like '>' or '{ $var }'
      // This is why differentiating between the start of a segment and the actual content of the segment is useful.
      // We can ignore any whitespace around the start, and once we're inside the actual content, then whitespace is counted to preserve the meaning of the command.
      ' ', '\n', '\t' => tokenizer_state,

      // We're ready to run the command.
      ';', '|' => .end,

      else => switch (tokenizer_state) {
        .interpol_start => .interpol_subcommand,
        .redirect_start => .redirect_file,
        // If we aren't in an interpolation, a redirect, or a comment, then we must be in a string segment.
        .start, .string, .interpol_end, .end => .string,
        // For all other chars, latch to whatever the prev state was, so it keeps appending chars.
        .interpol_subcommand, .interpol_variable, .redirect_file, .redirect_variable, .comment => tokenizer_state
      }
    };

    switch (tokenizer_state) {
      .comment => continue,
      .end => {
        //
        // Run it!
        // 1. Apply interpolations for the command
        // 2. Do command/argv splitting on the result
        //    - this means spaces within interpolations will be accounted for during arg splitting, similar to bash/sh. (fish doesn't do that!)
        // 3. Prepare redirection destination:
        //    - if it's a variable, create it if it doesn't exist
        //    - if it's a file, apply interpolations (supports variables and subcommands)
        //      - if the interpolation resolves to something that starts with $, it is saved to a file with that literal name! It does NOT go back to being saved to a variable.
        // 4. If it's piped, create the % variable
        // 5. Call execvp()/std.process.spawn()
        //
        const is_piped = char == '|';
        log.info("is_piped: {}\n", .{is_piped});

        // start it all again!
        tokenizer_state = .start;
      },
      else => {}
    }

    print("{c} {}\n", .{char, tokenizer_state});
  } else |err| switch (err) {
    error.EndOfStream => log.info("Finished running script.", .{}),
    else => return err,
  }
}
