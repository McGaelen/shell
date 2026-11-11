#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>

#include "String.c"

typedef enum : uint8_t {
  TS_START,
  TS_COMMENT,
  TS_STRING,
  TS_INTERPOL_START,
  TS_INTERPOL_VARIABLE,
  TS_INTERPOL_SUBCOMMAND,
  TS_INTERPOL_END,
  TS_REDIRECT_START,
  TS_REDIRECT,
} TokenizerState;

typedef enum : uint8_t {
  CMDSG_STRING,
  CMDSG_INTERPOL,
} CommandSegmentType;

typedef enum : uint8_t {
  INTERPOL_VARIABLE,
  INTERPOL_SUBCOMMAND,
} InterpolationType;

typedef enum : uint8_t {
  RDT_NONE, // When there was no redirection statement in the command.
  RDT_FILE,
  RDT_VARIABLE,
} RedirectionDestinationType;

typedef struct {
  DynamicArray da;
  RedirectionDestinationType rdt;
  String *rdt_name; // This either refers to a file or variable depending on the value of `rdt`.
} CommandSegmentList;

typedef struct {
  InterpolationType type;
  union {
    String variable;
    CommandSegmentList subcommand;
  };
} Interpolation;

typedef struct {
  CommandSegmentType type;
  union {
    String string;
    Interpolation interpol;
  };
} CommandSegment;

CommandSegmentList csl_init() {
  return (CommandSegmentList) {
    .da = da_init(5, sizeof(CommandSegment)),
  };
}

CommandSegment* csl_get(CommandSegmentList* csl, size_t idx) {
  da_bounds_check(&csl->da, idx);
  return &((CommandSegment*)csl->da.ptr)[idx];
}

size_t csl_len(CommandSegmentList* csl) {
  return csl->da.len;
}

void csl_append(CommandSegmentList* csl, CommandSegment new_csl) {
  DynamicArray* da = &csl->da;

  da_expand(da, 1);

  CommandSegment* array = (CommandSegment*)da->ptr;
  array[da->len - 1] = new_csl;
}

void csl_clear(CommandSegmentList* str) {
  da_clear(&str->da);
}

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
  TokenizerState tokenizer_state = TS_START;
  // CommandSegmentList csl = csl_init();
  // CommandSegment seg;
  // String command = str_init();
  // String redirection = str_init();

  while (fread(&buf, 1, 1, script_file) > 0) {
    // TODO: Just print out one char at a time, and print when tokenizer state changes.

    // CommandSegment* current = csl_get(&csl, csl_len(&csl));

    // If we're inside a comment, skip all characters until we reach a newline.
    if (tokenizer_state == TS_COMMENT) {
      if (buf == '\n') {
        tokenizer_state = TS_START;
      }
      continue;
    }

    switch (buf) {
      case '#':
        tokenizer_state = TS_COMMENT;
        break;
      case '>':
        tokenizer_state = TS_REDIRECT_START;
        break;
      case '{':
        tokenizer_state = TS_INTERPOL_START;
        break;
      case '}':
        tokenizer_state = TS_INTERPOL_END;
        break;
      case '$':
        break;
      case ';':
      case '|':
        bool is_piped = buf == '|';
        tokenizer_state = TS_START;
        break;
      default:
        if (tokenizer_state == TS_INTERPOL_START) {
          tokenizer_state = TS_INTERPOL_VARIABLE; // OR MAYBE TS_INTERPOL_SUBCOMMAND
        }
        // if (tokenizer_state == TS_COMMAND_SEGMENT) {
        //   if (current->type == CMDSG_INTERPOL) {
        //     if (current->interpol.type == INTERPOL_VARIABLE) {
        //       str_append(&current->interpol.variable, buf);
        //     } else {
        //       // subcommands go here
        //     }
        //   } else {
        //     // not an interpol, just a regular string
        //     // if we don't currently have a
        //     str_append(&current->string, buf);
        //   }
        // } else if (tokenizer_state == TS_REDIRECTION) {
        //   // setup the redirection. For now, just throw it in a buffer.
        //   str_append(&redirection, buf);
        // }
        break;
    }
  }

  printf("Finished running script.\n");
}
