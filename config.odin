package main

import "core:fmt"
import "core:strconv"
import "core:text/regex"
import "core:strings"
import "core:os"

import rl "vendor:raylib"

Config :: struct {
	background: rl.Color,
	vsync: bool,
	fullscreen: bool,
	resizable: bool,	
}

parse_hsv_color :: proc(text: string) -> (rl.Color, bool) {
  hsv_regex, err := regex.create("\\s?\\{\\s?\\w+\\s?=\\s?(\\d+.?\\d*)\\s?,\\s?\\w+\\s?=\\s?(\\d+.?\\d*)\\s?,\\s?\\w+\\s?=\\s?(\\d+.?\\d*)\\s?\\}\\s?")

  if err != nil { return rl.Color{}, false }

  hsv_capture, ok := regex.match_and_allocate_capture(hsv_regex, text)
  if (!ok) { return rl.Color{}, false }

  hsv_values: [3]f32 = {}

  for i in 0..<3 {
    v, ok := strconv.parse_f32(hsv_capture.groups[i+1])
    if (!ok) { return rl.Color{}, false }
    hsv_values[i] = v;
  }

  return rl.ColorFromHSV(hsv_values[0], hsv_values[1], hsv_values[2]), true
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
      case "background":
        color, ok := parse_hsv_color(value)
        if (ok) { config.background = color }
        break
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
    fmt.sbprintf(&sb, "background = {{ h = %f, s = %f, v = %f }}\nvsync = %t\nfullscreen = %t\nresizable = %t",
  bg_vec.x, bg_vec.y, bg_vec.z, config.vsync, config.fullscreen, config.resizable)
  )
}