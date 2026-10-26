package config

import "core:reflect"
import "core:io"
import "core:fmt"
import "core:log"
import "base:runtime"
import "core:strings"

write_array :: proc(builder: ^strings.Builder, info: runtime.Type_Info_Array, value: any, depth: int) {
  fmt.sbprint(builder, "[")
  for i in 0..<info.count {
    elem_ptr := uintptr(value.data) + uintptr(info.elem_size * i)
    if i != 0 {
      fmt.sbprint(builder, ", ")
    }
    write_value(builder, any{data = rawptr(elem_ptr), id = info.elem.id}, depth)
  }
  fmt.sbprint(builder, "]")
}

write_struct :: proc(builder: ^strings.Builder, info: runtime.Type_Info_Struct, value: any, depth: int) {
  if depth > 0 do fmt.sbprint(builder, "{\n")
  
  for field, field_index in reflect.struct_fields_zipped(value.id) {
    if field_index != 0 {
      fmt.sbprint(builder, "\n")
    }
    
    fmt.sbprintf(builder, "%s", strings.repeat("  ", depth))
    write_string(builder, field.name)
    fmt.sbprint(builder, " = ")

    field_ptr := uintptr(value.data) + field.offset

    write_value(builder, any{data = rawptr(field_ptr), id = field.type.id}, depth + 1)
  }

  if depth > 0 do fmt.sbprintf(builder, "\n%s}", strings.repeat("  ", depth - 1))
}

write_bool :: proc(builder: ^strings.Builder, value: any) {
  switch type in value {
    case b8, b16, b32, b64, bool:
      fmt.sbprintf(builder, "%t", type)
    case:
      log.fatalf("Non boolean type '%v' made it into `write_bool`", value.id)
  }
}

write_float :: proc(builder: ^strings.Builder, value: any) {
  switch type in value {
    case f16, f32, f64,
    f16be, f32be, f64be,
    f16le, f32le, f64le:
      fmt.sbprintf(builder, "%f", type)
    case:
      log.fatalf("Non float type '%v' made it into `write_float`", value.id)
  }
}

write_int :: proc(builder: ^strings.Builder, value: any) {
  switch type in value {
    case int, uint,
    u8, u16, u32, u64, u128,
      u16be, u32be, u64be, u128be,
      u16le, u32le, u64le, u128le,
    i8, i16, i32, i64, i128,
      i16be, i32be, i64be, i128be,
      i16le, i32le, i64le, i128le:
      fmt.sbprintf(builder, "%d", type)
    case:
      log.fatalf("Non integer type '%v' made it into `write_int`", value.id)
  }
}

write_string :: proc(builder: ^strings.Builder, value: any) {
  switch type in value {
    case string, cstring, string16, cstring16:
      fmt.sbprintf(builder, "%q", type)
    case rune:
      fmt.sbprintf(builder, "'")
      io.write_escaped_rune(strings.to_writer(builder), type, '"')
      fmt.sbprintf(builder, "'")
    case:
      log.fatalf("Non string type '%v' made it into `write_string`", value.id)
  }
}

write_value :: proc(builder: ^strings.Builder, value: any, depth: int = 0) {
  type_info := runtime.type_info_base(type_info_of(value.id))

  #partial switch variant in type_info.variant {
    case runtime.Type_Info_String:
    case runtime.Type_Info_Rune:
      write_string(builder, value)
    case runtime.Type_Info_Integer:
      write_int(builder, value)
    case runtime.Type_Info_Float:
      write_float(builder, value)
    case runtime.Type_Info_Boolean:
      write_bool(builder, value)
    case runtime.Type_Info_Struct:
      write_struct(builder, variant, value, depth)
    case runtime.Type_Info_Array:
      write_array(builder, variant, value, depth)
    case runtime.Type_Info_Named:
      log.fatal("reflect.type_info_base is broken?")
    case:
      unimplemented(fmt.tprintf("%v %v", value, type_info))
  }
}