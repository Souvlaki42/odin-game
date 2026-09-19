package main

import os "core:os"
import strings "core:strings"

import rl "vendor:raylib"

State :: enum {
	EMPTY,
	GROWING,
	READY,
}

Entity :: struct {
	name:     string,
	textures: [dynamic]rl.Texture2D,
	position: rl.Vector2,
	frame:    int,
	state:    State,
}

entity_collide :: proc(entity: ^Entity, point: rl.Vector2) -> bool {
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
			texture_path := strings.clone_to_cstring(
				strings.concatenate({sprite_path, "/", entry.name}),
			)
			defer delete(texture_path)
			append(&sprites, rl.LoadTexture(texture_path))
		}
	}

	entity.name = name
	entity.position = position
	entity.frame = 0
	entity.textures = sprites
	entity.state = State.EMPTY

	return entity
}

main :: proc() {
	rl.InitWindow(480, 360, "Odin Game")
	defer rl.CloseWindow()

	rl.SetWindowState(rl.ConfigFlags{.WINDOW_RESIZABLE, .WINDOW_MAXIMIZED, .VSYNC_HINT})

	background_color := rl.ColorFromHSV(108.0, 0.6, 0.73)

	entities := make([dynamic]Entity)
	defer delete(entities)

	append(&entities, entity_make("Farm Plot", rl.Vector2{35, 600}))
	append(&entities, entity_make("Fishing Plot", rl.Vector2{210, 82}))
	append(&entities, entity_make("Pig", rl.Vector2{256, 229}))
	append(&entities, entity_make("Goat", rl.Vector2{454, 279}))
	append(&entities, entity_make("Hen", rl.Vector2{48, 153}))
	append(&entities, entity_make("Sheep", rl.Vector2{73, 43}))
	append(&entities, entity_make("Cow", rl.Vector2{367, 32}))

	defer {
		for entity in entities {
			for texture in entity.textures {
				rl.UnloadTexture(texture)
			}
		}
	}

	for (!rl.WindowShouldClose()) {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		if (entity_collide(&entities[0], rl.GetMousePosition()) &&
			   rl.IsMouseButtonDown(rl.MouseButton.LEFT)) {
			rl.ClearBackground(rl.RED)
		} else {
			rl.ClearBackground(background_color)
		}

		for &entity in entities {
			rl.DrawTextureV(entity.textures[entity.frame], entity.position, rl.WHITE)
		}

		rl.DrawText(rl.TextFormat("FPS: %d", rl.GetFPS()), 10, 10, 24, rl.WHITE)
	}
}
