#define _GNU_SOURCE

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

typedef struct {
  char *ptr;
  uint64_t len;
  uint64_t cap;
} String;

String String_init() {
  const uint cap = 1;

  char *ptr = mmap(
    NULL,
    cap,
    PROT_READ | PROT_WRITE,
    MAP_PRIVATE | MAP_ANONYMOUS,
    -1,
    0
  );

  if (ptr == MAP_FAILED) {
    perror("Failed to call mmap()");
    exit(1);
  }

  return (String) {
    .ptr = ptr,
    .len = 0,
    .cap = cap,
  };
}

void String_append(String *str, char c) {
  if (str->len == str->cap) {
    str->ptr = mremap(str->ptr, str->cap, str->cap + 1, MREMAP_MAYMOVE);

    if (str->ptr == MAP_FAILED) {
      perror("Failed to resize String");
      exit(1);
    }

    str->cap += 1;
  }

  str->ptr[str->len] = c;
  str->len += 1;
}

void String_print(String *str) {
  for (int i = 0; i < str->len; i++) {
    printf("%c", str->ptr[i]);
  }
  printf("\n");
}

void String_clear(String *str) {
  str->len = 0;
}
