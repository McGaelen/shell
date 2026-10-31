package main

import "core:mem"
import "core:fmt"

TokenizerState :: enum {
	statement_start,
	statement_end,
	command_start,
	comment_start,
}

STEP :: 1

String :: struct {
	ptr: []rune,
	len: u64,
}

String_make :: proc(capacity: u64 = STEP) -> String {
	ptr := make([]rune, capacity)
	return String{
		ptr = ptr,
		len = 0,
	}
}

String_delete :: proc(self: ^String) {
	delete(self.ptr)
}

String_append :: proc(self: ^String, char: rune) {
	if self.len == len(self.ptr) {
		new_len := self.len + STEP

		self.ptr, err = mem.resize(self.ptr, len(self.ptr), len(self.ptr) + STEP)
		if err {

		}
	}
}

main :: proc() {

}
