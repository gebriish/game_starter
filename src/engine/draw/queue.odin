package draw

QuadCmd :: struct {
  position : vec2,
  size : vec2,
  pivot : Pivot,
  color : vec4,
  texture_id : u32,
  texture_coords : vec4,
}

DrawCmd :: union {
  QuadCmd,
  RenderPass,
}

DrawQueue :: struct {
  list : [dynamic]DrawCmd,
}

queue_create :: proc(initial_capacity : uint, allocator := context.allocator) -> DrawQueue {
  queue := DrawQueue {}
  queue.list = make([dynamic]DrawCmd, 0, initial_capacity, allocator)
  return queue
}

queue_begin :: proc(queue : ^DrawQueue) {
  clear(&queue.list)
}

queue_push_cmd :: proc(queue: ^DrawQueue, cmd : DrawCmd) {
  append(&queue.list, cmd)
}


/*
  Takes draw queue and sort DrawCalls in between RenderPasses
*/
queue_resolve :: proc(queue : ^DrawQueue) {
  
}

queue_exec :: proc(queue : DrawQueue) {
  for cmd in queue.list {
    switch type in cmd {
    case QuadCmd : 
    case RenderPass :
      end_frame()
      begin_frame(type)
    }
  }
}
