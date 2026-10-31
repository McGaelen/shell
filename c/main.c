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

  while (fread(&buf, 1, 1, script_file) > 0) {
    switch (buf) {
      case ' ':
      case '\t':
      case '\n':
        continue;
      case '#':
        tokenizer_state = TS_COMMENT;
        break;
      case '>':
        tokenizer_state = TS_REDIRECTION;
      case ';':
        // do the thing
        break;
      // default:
        // no op
    }

    switch (tokenizer_state) {
      case TOKENIZER_STATE_STATEMENT_START:
        String_append(&statement, buf);
        break;
      case TS_COMMENT:
        String_print(&statement);
        tokenizer_state = TOKENIZER_STATE_STATEMENT_START;
        String_clear(&statement);
        break;
      default:
        printf("Unknown state! %i\n", tokenizer_state);
        exit(1);
    }
  }

  printf("Finished running script.\n");
}
