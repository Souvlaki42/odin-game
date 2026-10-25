package main

import "core:fmt"
import "core:strings"
import "core:os"

Config :: struct {
	vsync: bool,
	fullscreen: bool,
	resizable: bool,	
}







parse_config :: proc() -> Config {
	config := Config{ background = rl.ColorFromHSV(108.0, 0.6, 0.73), vsync = true, fullscreen = false, resizable = true }

	data, err := os.read_entire_file("config.toml", context.allocator)
	if err != nil {
		write_config(&config)
		return config
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		key_value := strings.split_n(line, "=", 2)
    key := strings.trim_space(key_value[0])
    value := strings.trim_space(key_value[1])

    switch (key) {
      case "vsync":
        config.vsync = value == "true"
        break
      case "fullscreen":
        config.fullscreen = value == "true"
        break
      case "resizable":
        config.resizable = value == "true"
        break
    }
	}

	return config
}

write_config:: proc(config: ^Config) {
  sb, alloc_err := strings.builder_make()
  if (alloc_err != nil) { return }

  bg_vec := rl.ColorToHSV(config.background)

  _ = os.write_entire_file_from_string(
    "config.toml",
    fmt.sbprintf(&sb, "vsync = %t\nfullscreen = %t\nresizable = %t", config.vsync, config.fullscreen, config.resizable)
  )
}