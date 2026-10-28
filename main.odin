package main

import "core:log"
import os "core:os"
import strings "core:strings"

import rl "vendor:raylib"


Entity :: struct {
	name:     string,
	textures: [dynamic]rl.Texture2D,
	position: rl.Vector2,
	frame:    int,
	moving:   bool,
	phase:    enum {
		EMPTY,
		GROWING,
		READY,
	},
}

entity_collide :: proc(entity: ^Entity, point: rl.Vector2) -> bool {
	// TASK(20260921-195934): make rects reflect texture shape
	if len(entity.textures) <= 0 do return false
	entity_rect := rl.Rectangle {
		entity.position.x,
		entity.position.y,
		cast(f32)entity.textures[entity.frame].width,
		cast(f32)entity.textures[entity.frame].height,
	}

	return rl.CheckCollisionPointRec(point, entity_rect)
}

entity_make :: proc(name: string, position: rl.Vector2) -> Entity {
	entity := Entity{}

	sprites := make([dynamic]rl.Texture2D)

	sprite_path := strings.concatenate({"assets/", name})
	entries, _ := os.read_directory_by_path(sprite_path, -1, context.allocator)
	defer delete(entries)

	for entry in entries {
		if strings.contains(entry.name, ".png") {
			append(&sprites, rl.LoadTexture(rl.TextFormat("%s/%s", sprite_path, entry.name)))
		}
	}

	if len(sprites) <= 0 {
		log.fatalf("Entity '%s' has no sprites?", name)
		return entity
	}

	entity.name = name
	entity.position = position
	entity.frame = 0
	entity.textures = sprites
	entity.phase = .EMPTY

	return entity
}

render_text_menu :: proc(
	entries: ^[dynamic]cstring,
	font_size: i32,
	color: rl.Color,
	offset: rl.Vector2 = {10, 10},
) {
	v_offset := offset.y

	for entry in entries {
		rl.DrawText(entry, cast(i32)offset.x, cast(i32)v_offset, font_size, color)
		v_offset += offset.y + cast(f32)font_size
	}
}

main :: proc() {
	context.logger = log.create_console_logger()

	rl.InitWindow(480, 360, "Odin Game")
	defer rl.CloseWindow()

	window_state: rl.ConfigFlags = {.WINDOW_MAXIMIZED, .WINDOW_RESIZABLE, .VSYNC_HINT}
	rl.SetWindowState(window_state)
	debug_entries := make([dynamic]cstring)
	defer delete(debug_entries)

	debug := false
	move := false

	entities := [7]Entity {
		entity_make("Farm", rl.Vector2{35, 600}),
		entity_make("Fish", rl.Vector2{210, 82}),
		entity_make("Pig", rl.Vector2{256, 229}),
		entity_make("Goat", rl.Vector2{454, 279}),
		entity_make("Hen", rl.Vector2{48, 153}),
		entity_make("Sheep", rl.Vector2{73, 43}),
		entity_make("Cow", rl.Vector2{367, 32}),
	}

	defer {
		for entity in entities {
			for texture in entity.textures {
				rl.UnloadTexture(texture)
			}
		}
	}

	for (!rl.WindowShouldClose()) {
		clear(&debug_entries)

		if (rl.IsKeyPressed(rl.KeyboardKey.F3)) {
			debug = !debug
		}

		if (rl.IsKeyPressed(rl.KeyboardKey.M)) {
			move = !move
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.ColorFromHSV(108, 0.6, 0.73))

		for &entity in entities {
			if len(entity.textures) <= 0 do continue

			if (move &&
				   entity_collide(&entity, rl.GetMousePosition()) &&
				   rl.IsMouseButtonPressed(rl.MouseButton.LEFT)) {
				entity.moving = true
			}

			if (entity_collide(&entity, rl.GetMousePosition()) &&
				   rl.IsMouseButtonReleased(rl.MouseButton.LEFT)) {
				entity.moving = false
			}

			if (entity.moving) {
				entity.position =
					rl.GetMousePosition() -
					rl.Vector2 {
							cast(f32)entity.textures[entity.frame].width / 2,
							cast(f32)entity.textures[entity.frame].height / 2,
					}
			}

			rl.DrawTextureV(entity.textures[entity.frame], entity.position, rl.WHITE)
		}

		if (debug) {
			append(&debug_entries, rl.TextFormat("FPS: %d", rl.GetFPS()))
			append(
				&debug_entries,
				rl.TextFormat("Mouse: (%d, %d)", rl.GetMouseX(), rl.GetMouseY()),
			)
			append(&debug_entries, rl.TextFormat("Move mode: %s", move ? "true" : "false"))

			render_text_menu(&debug_entries, 24, rl.WHITE)
		}
	}
}
