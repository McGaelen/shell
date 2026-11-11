#define _GNU_SOURCE

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <signal.h>

// A growable array of elements. The elements will always be contiguous.
// Index-based access should always be used, since `ptr` can be moved,
// invalidating any pointers your code keeps track of.
typedef struct {
  void* ptr;
  size_t len; // Number of elements
  size_t cap; // Total available capacity for elements
  size_t step; // Size in bytes of each element
} DynamicArray;

// Creates a DynamicArray and allocates memory to fit `cap` elements.
// `step` is `sizeof()` whatever data you want to store.
DynamicArray da_init(size_t cap, size_t step) {
  cap = cap <= 0 ? 5 : cap;
  size_t num_bytes = step * cap;

  char *ptr = mmap(
    NULL,
    num_bytes,
    PROT_READ | PROT_WRITE,
    MAP_PRIVATE | MAP_ANONYMOUS,
    -1,
    0
  );

  if (ptr == MAP_FAILED) {
    perror("Failed to call mmap()");
    exit(1);
  }

  return (DynamicArray) {
    .ptr = ptr,
    .len = 0,
    .cap = cap,
    .step = step
  };
}

// Increases the length of the array by the given amount.
// Memory will be reallocated and possibly moved if `len` becomes greater than `cap`
// - in this case, `ptr` will be updated to the new location.
void da_expand(DynamicArray* da, size_t amt) {
  const size_t pad = 5;

  size_t newlen = da->len + amt;

  if (newlen >= da->cap) {
    size_t newcap = da->cap + (newlen - da->cap) + pad;
    da->ptr = mremap(
      da->ptr,
      da->cap,
      newcap,
      MREMAP_MAYMOVE
    );

    if (da->ptr == MAP_FAILED) {
      perror("Failed to resize String");
      exit(1);
    }

    da->cap = newcap;
  }

  da->len = newlen;
}

void da_bounds_check(DynamicArray* da, size_t idx) {
  if (idx >= 0 && idx < da->len) {
    return;
  }
  raise(SIGTRAP);
  printf("Bad array access at index %zu. len: %zu, cap: %zu\n", idx, da->len, da->cap);
  exit(1);
}

void da_clear(DynamicArray* da) {
  da->len = 0;
}


// Dynamically sized string.
// Don't interact directly with the underlying DynamicArray.
// Instead, only use these functions as your interface.
// Don't store pointers to indexes, because they can move when appending data.
// It will maintain a null byte at the end of the string for C string compatability.
// (which is another reason why you don't interact with the DynamicArray - it's length will always be 1 extra to include the null byte!)
typedef struct {
  DynamicArray da;
} String;

String str_init() {
  DynamicArray da = da_init(5, sizeof(char));

  da_expand(&da, 1);
  ((char*)da.ptr)[0] = '\0';

  return (String) {
    .da = da
  };
}

char str_get(String* str, size_t idx) {
  da_bounds_check(&str->da, idx);
  return ((char*)str->da.ptr)[idx];
}

size_t str_len(String* str) {
  return str->da.len - 1;
}

void str_append(String* str, char c) {
  DynamicArray* da = &str->da;

  da_expand(da, 1);

  char* array = (char*)da->ptr;
  array[da->len - 2] = c;
  array[da->len - 1] = '\0';
}

void str_clear(String* str) {
  DynamicArray* da = &str->da;

  da_clear(da);
  da_expand(da, 1);
  ((char*)da->ptr)[0] = '\0';
}
