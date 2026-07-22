package camera

System :: struct {
	devices_raw: rawptr,
	device_count: u32,
}

system_open :: proc() -> (system: System, ok: bool) {
	devices_raw, count, opened := camera_list_devices()
	if !opened { return {}, false }
	system.devices_raw = devices_raw
	system.device_count = count
	return system, true
}

system_close :: proc(system: ^System) {
	if system == nil { return }
	camera_free_device_list(system.devices_raw, system.device_count)
	system^ = {}
}

device_count :: proc(system: ^System) -> u32 {
	if system == nil { return 0 }
	return system.device_count
}

device_name :: proc(system: ^System, index: u32) -> string {
	if system == nil || index >= system.device_count { return "Unknown" }
	return camera_get_device_name(system.devices_raw, index)
}
