package ui


@(deferred_none=close_box)
panel :: proc(config : Config) -> bool {
  open_box()
  config_box(config)
  return true
}

