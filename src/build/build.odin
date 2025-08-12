package build

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:time"

BuildTarget :: enum {
  windows,
  linux,
}

when ODIN_OS == .Windows {
  EXE_NAME :: "game.exe"
  TARGET :: BuildTarget.windows
}
else {
  EXE_NAME :: "game"
  TARGET :: BuildTarget.linux
}

main :: proc() {
  for arg in os.args {
    switch arg {
    case "sprite":
    }
  }

  compile_game()
}

pack_sprites :: proc() {
}

compile_game :: proc() {
  begin_time := time.now()
  defer {
    fmt.printf("Build done [%v]\n", time.diff(begin_time, time.now()))
  }

  fmt.printf("Build target [%v]\n", TARGET)

  current_wd := os.get_current_directory()
  bin_dir := "bin"
  out_dir := fmt.tprintf("%v/%v", bin_dir, TARGET)

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
      "-subsystem:windows" when TARGET == .windows else ""
    }
    run_cmd(..c[:])
  }
}
