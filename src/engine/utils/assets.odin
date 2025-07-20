package utils

import "core:os"
import "core:path/filepath"

@(private) _EXE_DIR : string = ""

load_exec_dir :: proc() {
  assert(len(_EXE_DIR) == 0, "repeatedly calling app::load_exec_dir")
	_EXE_DIR = filepath.dir(os.args[0])
}

get_path_temp :: proc(relative : string) -> string {
	paths := []string {
		_EXE_DIR, relative
	}
	return filepath.join(paths, allocator=context.temp_allocator)	
}