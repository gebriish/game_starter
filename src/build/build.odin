package build

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:time"

import stbi "vendor:stb/image"

when ODIN_OS == .Windows {
  EXE_NAME :: "game.exe"
}
else {
  EXE_NAME :: "game"
}

BuildTarget :: enum {
  windows,
  linux,
  macos,
}

run_cmd :: proc(cmd: ..string) -> os2.Error {
  process, start_err := os2.process_start(os2.Process_Desc{
    command=cmd,
		stdout = os2.stdout,
		stderr = os2.stderr,
	})
	if start_err != nil {
		fmt.eprintln("Error:", start_err) 
		return start_err
	}

	_, wait_err := os2.process_wait(process)
	if wait_err != nil {
		fmt.eprintln("Error:", wait_err) 
		return wait_err
	}

	return nil
}

make_directory_if_not_exist :: proc(path: string) {
	if !os.exists(path) {
		err := os2.make_directory_all(path)
		if err != nil {
      fmt.println("Err : ", err)
		}
	}
}

main :: proc()
{
  begin_time := time.now()
  defer {
    fmt.println("Build done in ", time.diff(begin_time, time.now()))
  }

  build_target : BuildTarget : .windows when ODIN_OS == .Windows else .linux when ODIN_OS == .Linux else .macos   

  fmt.printf("Build target [%v]\n", build_target)

  current_wd := os.get_current_directory()
  bin_dir := "bin"
  out_dir := fmt.tprintf("%v/%v", bin_dir, build_target)
  
  full_out_dir_path := fmt.tprintf("%v/%v", current_wd, out_dir)
  fmt.printf("Build path [%v]\n", full_out_dir_path)

  make_directory_if_not_exist(full_out_dir_path)

  { // build command
    c := [?]string {
      "odin",
      "build",
      "src",
      "-debug",
      "-collection:engine=src/engine",
      "-collection:user=src",
      fmt.tprintf("-out:%v/%v", out_dir, EXE_NAME),
      // on release builds "-subsystem:windows" when build_target == .windows else ""
    }

    run_cmd(..c[:])
  }
}
