package main

import rl "vendor:raylib"

main :: proc() {
  rl.InitWindow(1280, 720, "Odin Game")
  defer rl.CloseWindow()
  
  rl.SetTargetFPS(60)
  rl.SetWindowState(rl.ConfigFlags{.WINDOW_RESIZABLE})
  
  for (!rl.WindowShouldClose()) {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.ColorFromHSV(108.0, 0.6, 0.73))
  }
}
