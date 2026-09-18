package main

import fmt "core:fmt"
import os "core:os"
import strings "core:strings"

import rl "vendor:raylib"

VSYNC :: true

State :: enum {
	EMPTY,
	GROWING,
	READY,
}

Entity :: struct {
	name:             string,
	textures:         [dynamic]rl.Texture2D,
	position:         rl.Vector2,
	frame:            int,
	state:            State,
	animation_clock:  Clock,
	collection_clock: Clock,
}

Clock :: struct {
	cooldown: f32,
	timer:    f32,
}

entity_make :: proc(
	name: string,
	position: rl.Vector2,
	collection_cooldown: f32,
	animation_cooldown: f32 = 0,
) -> Entity {
	entity := Entity{}

	sprites := make([dynamic]rl.Texture2D)
	defer delete(sprites)

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

	collection_clock := Clock{}
	collection_clock.timer = 0
	collection_clock.cooldown = collection_cooldown

	animation_clock := Clock{}
	animation_clock.timer = 0
	if (animation_cooldown == 0) {
		animation_clock.cooldown = collection_cooldown
	} else {
		animation_clock.cooldown = animation_cooldown
	}

	entity.name = name
	entity.position = position
	entity.animation_clock = animation_clock
	entity.collection_clock = collection_clock
	entity.frame = 0
	entity.textures = sprites
	entity.state = State.EMPTY

	return entity
}

entity_interacted := proc(entity: ^Entity) -> bool {
	mouse_position := rl.GetMousePosition()
	texture_scale := rl.Vector2 {
		cast(f32)entity.textures[entity.frame].width,
		cast(f32)entity.textures[entity.frame].height,
	}
	return(
		rl.IsMouseButtonPressed(rl.MouseButton.LEFT) &&
		mouse_position.x >= entity.position.x &&
		mouse_position.y >= entity.position.y &&
		mouse_position.x <= entity.position.x + texture_scale.x &&
		mouse_position.y <= entity.position.y + texture_scale.y \
	)
}

entity_update :: proc(entity: ^Entity) {
	entity.animation_clock.timer += rl.GetFrameTime()
	entity.collection_clock.timer += rl.GetFrameTime()

	if ((entity.state == State.GROWING) &&
		   (entity.animation_clock.timer >= entity.animation_clock.cooldown)) {
		entity.animation_clock.timer -= entity.animation_clock.cooldown

		entity.frame += 1

		if (entity.frame == len(entity.textures) - 1) {
			entity.state = State.READY
		}
	}

	if (entity_interacted(entity)) {
		switch entity.state {
		case State.EMPTY:
			entity.frame = 0
			entity.state = State.GROWING
			break
		case State.READY:
			fmt.eprintln("not implemented yet")
		case State.GROWING:
			break
		}
	}

	rl.DrawTextureV(entity.textures[entity.frame], entity.position, rl.WHITE)
}

main :: proc() {
	rl.InitWindow(480, 360, "Odin Game")
	defer rl.CloseWindow()

	rl.SetWindowState(rl.ConfigFlags{.WINDOW_RESIZABLE, .WINDOW_MAXIMIZED})

	if (VSYNC) {
		monitor := rl.GetCurrentMonitor()
		refresh_rate := rl.GetMonitorRefreshRate(monitor)
		rl.SetTargetFPS(refresh_rate)
	}

	paused := false

	entities := make([dynamic]Entity)
	defer delete(entities)

	append(&entities, entity_make("Farm Plot", rl.Vector2{100, 267}, 60, 0.031))
	append(&entities, entity_make("Fishing Plot", rl.Vector2{210, 82}, 60, 0.031))
	append(&entities, entity_make("Pig", rl.Vector2{256, 229}, 60, 0.031))
	append(&entities, entity_make("Goat", rl.Vector2{454, 279}, 60, 0.031))
	append(&entities, entity_make("Hen", rl.Vector2{48, 153}, 60, 0.031))
	append(&entities, entity_make("Sheep", rl.Vector2{73, 43}, 60, 0.031))
	append(&entities, entity_make("Cow", rl.Vector2{367, 32}, 60, 0.031))


	for (!rl.WindowShouldClose()) {
		if rl.IsKeyPressed(.P) {
			paused = !paused
		}

		if (paused) {
			continue
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.ColorFromHSV(108.0, 0.6, 0.73))

		for &entity in entities {
			entity_update(&entity)
		}
	}
}
