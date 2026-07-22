package camera

import "core:sys/windows"
import "core:fmt"
import "core:mem"

Size :: struct {
	Width:  u32,
	Height: u32,
}

Stream :: struct {
	source_reader: ^IMFSourceReader,
	width:  u32,
	height: u32,
	subtype: GUID,
	devices_raw: rawptr,
	device_count: u32,
	frame_data:   [dynamic]u8,
}

camera_list_devices :: proc() -> (devices_raw: rawptr, count: u32, ok: bool) {
	windows.CoInitializeEx(nil, .MULTITHREADED)
	hr := MFStartup(MF_API_VERSION, MFSTARTUP_NOSOCKET)
	if hr != S_OK { return nil, 0, false }

	attrs: ^IMFAttributes
	hr = MFCreateAttributes(&attrs, 2)
	if hr != S_OK { MFShutdown(); return nil, 0, false }
	defer attrs.vtbl.Release(attrs)

	attrs.vtbl.SetGUID(attrs, var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP)

	hr = MFEnumDeviceSources(attrs, &devices_raw, &count)
	if hr != S_OK { MFShutdown(); return nil, 0, false }

	fmt.printfln("camera_list_devices found %d devices", count)
	return devices_raw, count, true
}

camera_get_device_name :: proc(devices_raw: rawptr, index: u32) -> string {
	dev_arr := ([^]rawptr)(devices_raw)
	dev := (^IMFActivate)(dev_arr[index])
	name: windows.LPWSTR
	len: u32
	var_MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME := &GUID{0x60d0e559, 0x52f8, 0x4fa2, {0xbb, 0xce, 0xac, 0xdb, 0x34, 0xa8, 0xec, 0x01}}
	if dev.vtbl.GetAllocatedString(dev, var_MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME, &name, &len) != S_OK {
		return "Unknown"
	}
	defer windows.CoTaskMemFree(name)
	name_slice := ([^]u16)(name)[:len]
	result, _ := windows.utf16_to_utf8_alloc(name_slice)
	return result
}

camera_free_device_list :: proc(devices_raw: rawptr, count: u32) {
	dev_arr := ([^]rawptr)(devices_raw)
	for i in 0 ..< count {
		dev := (^IMFActivate)(dev_arr[i])
		dev.vtbl.Release(dev)
	}
	CoTaskMemFree(devices_raw)
	MFShutdown()
}

stream_open :: proc(cam: ^Stream, device_index: u32) -> bool {
	windows.CoInitializeEx(nil, .MULTITHREADED)
	hr := MFStartup(MF_API_VERSION, MFSTARTUP_NOSOCKET)
	if hr != S_OK { fmt.eprintln("MFStartup:", hr); return false }

	attrs: ^IMFAttributes
	hr = MFCreateAttributes(&attrs, 2)
	if hr != S_OK { fmt.eprintln("MFCreateAttributes:", hr); return false }
	defer attrs.vtbl.Release(attrs)

	attrs.vtbl.SetGUID(attrs, var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE, var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP)

	devices_raw: rawptr
	count: u32
	hr = MFEnumDeviceSources(attrs, &devices_raw, &count)
	if hr != S_OK || count == 0 || device_index >= count {
		fmt.eprintln("No camera devices found")
		return false
	}

	cam.devices_raw = devices_raw
	cam.device_count = count

	dev_arr := ([^]rawptr)(devices_raw)
	dev := (^IMFActivate)(dev_arr[device_index])
	dev.vtbl.AddRef(dev)

	ms: rawptr
	hr = dev.vtbl.ActivateObject(dev, var_IID_IMFMediaSource, &ms)
	if hr != S_OK { fmt.eprintln("ActivateObject failed:", hr); return false }

	r: ^IMFSourceReader
	hr = E_FAIL
	sr_attrs: ^IMFAttributes
	if MFCreateAttributes(&sr_attrs, 1) == S_OK {
		sr_attrs.vtbl.SetUINT32(sr_attrs, var_MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, 1)
		hr = MFCreateSourceReaderFromMediaSource(ms, sr_attrs, &r)
		sr_attrs.vtbl.Release(sr_attrs)
	}
	if hr != S_OK {
		hr = MFCreateSourceReaderFromMediaSource(ms, nil, &r)
	}
	if hr != S_OK { fmt.eprintln("CreateSourceReader failed:", hr); return false }
	cam.source_reader = r

	nmt_raw: rawptr
	native_hr := r.vtbl.GetNativeMediaType(r, MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &nmt_raw)
	fmt.printfln("GetNativeMediaType: hr=0x%08x", native_hr)
	if native_hr == S_OK {
		nmt := (^IMFAttributes)(nmt_raw)

		val: u64
		if nmt.vtbl.GetUINT64(nmt, var_MF_MT_FRAME_SIZE, &val) == S_OK {
			cam.width  = u32(val >> 32)
			cam.height = u32(val & 0xFFFFFFFF)
			fmt.printfln("  -> native size: %dx%d", cam.width, cam.height)
		}

		out_mt: rawptr
		if MFCreateMediaType(&out_mt) == S_OK {
			omt := (^IMFAttributes)(out_mt)
			omt.vtbl.SetGUID(omt, var_MF_MT_MAJOR_TYPE, var_MFMediaType_Video)
			omt.vtbl.SetGUID(omt, var_MF_MT_SUBTYPE, var_MFVideoFormat_RGB32)
			frame_size := u64(cam.width) << 32 | u64(cam.height)
			omt.vtbl.SetUINT64(omt, var_MF_MT_FRAME_SIZE, frame_size)

			sc_hr := r.vtbl.SetCurrentMediaType(r, MF_SOURCE_READER_FIRST_VIDEO_STREAM, nil, omt)
			fmt.printfln("SetCurrentMediaType(RGB32): hr=0x%08x", sc_hr)
			if sc_hr == S_OK {
				cam.subtype = var_MFVideoFormat_RGB32^
				fmt.println("  -> using RGB32 output")
			} else {
				fmt.println("  -> RGB32 rejected, falling back to native subtype")
				nmt.vtbl.GetGUID(nmt, var_MF_MT_SUBTYPE, &cam.subtype)
				fmt.printfln("  -> native subtype: {%08x-%04x-%04x-%02x%02x%02x%02x%02x%02x%02x%02x}",
					cam.subtype.Data1, cam.subtype.Data2, cam.subtype.Data3,
					cam.subtype.Data4[0], cam.subtype.Data4[1], cam.subtype.Data4[2], cam.subtype.Data4[3],
					cam.subtype.Data4[4], cam.subtype.Data4[5], cam.subtype.Data4[6], cam.subtype.Data4[7])
			}
			omt.vtbl.Release(omt)
		}
		nmt.vtbl.Release(nmt)

		cur_mt: rawptr
		if r.vtbl.GetCurrentMediaType(r, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &cur_mt) == S_OK {
			cmt := (^IMFAttributes)(cur_mt)
			cur_val: u64
			if cmt.vtbl.GetUINT64(cmt, var_MF_MT_FRAME_SIZE, &cur_val) == S_OK {
				cam.width  = u32(cur_val >> 32)
				cam.height = u32(cur_val & 0xFFFFFFFF)
			}
			cmt.vtbl.Release(cmt)
		}
	}
	fmt.printfln("Final format: %dx%d", cam.width, cam.height)
	if cam.width == 0 || cam.height == 0 { cam.width = 640; cam.height = 480 }

	reserve(&cam.frame_data, int(cam.width * cam.height * 4))
	return true
}

stream_read_frame :: proc(cam: ^Stream) -> ([]u8, bool) {
	si: u32; fl: u32; sample: rawptr; ts: i64
	for {
		hr := cam.source_reader.vtbl.ReadSample(cam.source_reader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &si, &fl, &ts, &sample)
		if hr != S_OK { return cam.frame_data[:], false }
		if fl & MF_SOURCE_READERF_NATIVEMEDIATYPECHANGED != 0 {
			omt: rawptr
			if cam.source_reader.vtbl.GetCurrentMediaType(cam.source_reader, MF_SOURCE_READER_FIRST_VIDEO_STREAM, &omt) == S_OK {
				val: u64
				if (^IMFAttributes)(omt).vtbl.GetUINT64(omt, var_MF_MT_FRAME_SIZE, &val) == S_OK {
					cam.width = u32(val >> 32); cam.height = u32(val & 0xFFFFFFFF)
				}
				(^IMFAttributes)(omt).vtbl.Release(omt)
			}
		}
		if fl & MF_SOURCE_READERF_ENDOFSTREAM != 0 { return cam.frame_data[:], false }
		if sample != nil {
			so := (^IMFSample)(sample)
			bc: u32
			if so.vtbl.GetBufferCount(so, &bc) == S_OK && bc > 0 {
				buf: ^IMFMediaBuffer
				if so.vtbl.GetBufferByIndex(so, 0, &buf) == S_OK {
					d: ^u8; ml, cl: u32
					if buf.vtbl.Lock(buf, &d, &ml, &cl) == S_OK {
						sz := cam.width * cam.height * 4
						if cl >= sz {
							resize(&cam.frame_data, int(sz))
							mem.copy(&cam.frame_data[0], d, int(sz))
						} else {
							fmt.printfln("Frame too small: cl=%d need=%d", cl, sz)
						}
						buf.vtbl.Unlock(buf)
					}
					buf.vtbl.Release(buf)
				}
			}
			so.vtbl.Release(so)
			return cam.frame_data[:], true
		}
	}
}

stream_size :: proc(cam: ^Stream) -> Size {
	if cam == nil { return {} }
	return Size{cam.width, cam.height}
}

stream_close :: proc(cam: ^Stream) {
	if cam.source_reader != nil { cam.source_reader.vtbl.Release(cam.source_reader) }
	if cam.devices_raw != nil {
		dev_arr := ([^]rawptr)(cam.devices_raw)
		for i in 0 ..< cam.device_count {
			dev := (^IMFActivate)(dev_arr[i])
			dev.vtbl.Release(dev)
		}
		CoTaskMemFree(cam.devices_raw)
	}
	MFShutdown()
	delete(cam.frame_data)
}
