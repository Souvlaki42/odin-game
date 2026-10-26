package config

import "core:strconv"
import "core:os"
import "core:strings"
import "core:text/regex"

import rl "vendor:raylib"

Config :: struct {
	background: rl.Color,
	vsync: bool,
	fullscreen: bool,
	resizable: bool,
  positions: struct {
    Farm: rl.Vector2,
    Fish: rl.Vector2,
    Pig: rl.Vector2,
    Goat: rl.Vector2,
    Hen: rl.Vector2,
    Sheep: rl.Vector2,
    Cow: rl.Vector2
  }
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
	config := Config{
    background = rl.ColorFromHSV(108.0, 0.6, 0.73),
    vsync = true,
    fullscreen = false,
    resizable = true, 
    positions = {
      Farm = rl.Vector2{35, 600},
      Fish = rl.Vector2{210, 82},
      Pig = rl.Vector2{256, 229},
      Goat = rl.Vector2{454, 279},
      Hen = rl.Vector2{48, 153},
      Sheep = rl.Vector2{73, 43},
      Cow = rl.Vector2{367, 32}
    }
  }

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

  write_value(&sb, config^)

  write_err := os.write_entire_file_from_string(
    "config.toml",
    strings.to_string(sb)
  )
  if (write_err != nil) { return }
}