#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>

#include "String.c"

enum : uint8_t {
  TS_COMMENT,
  TS_COMMAND,
  TS_COMMAND_BETWEEN,
  TS_REDIRECTION,
};

int main(int argc, char **argv) {
  if (argc < 2) {
    printf("Please provide a script to execute.\n");
    exit(1);
  }

  FILE* script_file = fopen(argv[1], "r");
  if (!script_file) {
    perror("Failed to open file");
    exit(1);
  }

  char buf;
  uint8_t tokenizer_state = TS_COMMAND;
  String statement = String_init();
  String redirection = String_init();

  while (fread(&buf, 1, 1, script_file) > 0) {
    // If we're inside a comment, skip all characters until we reach a newline.
    if (tokenizer_state == TS_COMMENT) {
      if (buf == '\n') {
        tokenizer_state = TS_COMMAND;
      }
      continue;
    }

    switch (buf) {
      case ' ':
      case '\t':
      case '\n':
        if (tokenizer_state == TS_COMMAND) {
          String_append(&statement, buf);
        }
        break;
      case '#':
        tokenizer_state = TS_COMMENT;
        break;
      case '>':
        tokenizer_state = TS_REDIRECTION;
      case ';':
      case '|':
        // run it!
        break;
      default:
        if (tokenizer_state == TS_COMMAND || tokenizer_state == TS_COMMAND_BETWEEN) {
          String_append(&statement, buf);
        } else if (tokenizer_state == TS_REDIRECTION) {
          String_append(&redirection, buf);
        }
        break;
    }
  }

  printf("Finished running script.\n");
}
