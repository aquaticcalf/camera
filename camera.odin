package main

import "core:sys/windows"
import "core:fmt"
import "core:mem"

HRESULT :: windows.HRESULT
GUID :: windows.GUID
BOOL :: windows.BOOL
LPCWSTR :: windows.LPCWSTR

S_OK :: 0x00000000
E_FAIL :: -2147467259

IUnknownVtbl :: struct {
	QueryInterface: proc "system" (this: rawptr, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	AddRef:         proc "system" (this: rawptr) -> u32,
	Release:        proc "system" (this: rawptr) -> u32,
}
IUnknown :: struct { vtbl: ^IUnknownVtbl }

IMFAttributesVtbl :: struct {
	using _: IUnknownVtbl,

	GetItem:           proc "system" (this: rawptr, key: ^GUID, value: rawptr) -> HRESULT,
	GetItemType:       proc "system" (this: rawptr, key: ^GUID, pType: ^u32) -> HRESULT,
	CompareItem:       proc "system" (this: rawptr, key: ^GUID, value: rawptr, result: ^BOOL) -> HRESULT,
	Compare:           proc "system" (this: rawptr, other: rawptr, matchType: u32, result: ^BOOL) -> HRESULT,
	GetUINT32:         proc "system" (this: rawptr, key: ^GUID, value: ^u32) -> HRESULT,
	GetUINT64:         proc "system" (this: rawptr, key: ^GUID, value: ^u64) -> HRESULT,
	GetDouble:         proc "system" (this: rawptr, key: ^GUID, value: ^f64) -> HRESULT,
	GetGUID:           proc "system" (this: rawptr, key: ^GUID, value: ^GUID) -> HRESULT,
	GetStringLength:   proc "system" (this: rawptr, key: ^GUID, length: ^u32) -> HRESULT,
	GetString:         proc "system" (this: rawptr, key: ^GUID, buf: windows.LPWSTR, bufSize: u32, length: ^u32) -> HRESULT,
	GetAllocatedString: proc "system" (this: rawptr, key: ^GUID, str: ^windows.LPWSTR, length: ^u32) -> HRESULT,
	GetBlobSize:       proc "system" (this: rawptr, key: ^GUID, size: ^u32) -> HRESULT,
	GetBlob:           proc "system" (this: rawptr, key: ^GUID, buf: ^u8, bufSize: u32, size: ^u32) -> HRESULT,
	GetAllocatedBlob:  proc "system" (this: rawptr, key: ^GUID, buf: ^^u8, size: ^u32) -> HRESULT,
	GetUnknown:        proc "system" (this: rawptr, key: ^GUID, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	SetItem:           proc "system" (this: rawptr, key: ^GUID, value: rawptr) -> HRESULT,
	DeleteItem:        proc "system" (this: rawptr, key: ^GUID) -> HRESULT,
	DeleteAllItems:    proc "system" (this: rawptr) -> HRESULT,
	SetUINT32:         proc "system" (this: rawptr, key: ^GUID, value: u32) -> HRESULT,
	SetUINT64:         proc "system" (this: rawptr, key: ^GUID, value: u64) -> HRESULT,
	SetDouble:         proc "system" (this: rawptr, key: ^GUID, value: f64) -> HRESULT,
	SetGUID:           proc "system" (this: rawptr, key: ^GUID, value: ^GUID) -> HRESULT,
	SetString:         proc "system" (this: rawptr, key: ^GUID, value: windows.LPCWSTR) -> HRESULT,
	SetBlob:           proc "system" (this: rawptr, key: ^GUID, buf: ^u8, bufSize: u32) -> HRESULT,
	SetUnknown:        proc "system" (this: rawptr, key: ^GUID, unk: rawptr) -> HRESULT,
	LockStore:         proc "system" (this: rawptr) -> HRESULT,
	UnlockStore:       proc "system" (this: rawptr) -> HRESULT,
	GetCount:          proc "system" (this: rawptr, count: ^u32) -> HRESULT,
	GetItemByIndex:    proc "system" (this: rawptr, index: u32, key: ^GUID, value: rawptr) -> HRESULT,
	CopyAllItems:      proc "system" (this: rawptr, dest: rawptr) -> HRESULT,
}

IMFAttributes :: struct { vtbl: ^IMFAttributesVtbl }

IMFActivateVtbl :: struct {
	using _: IMFAttributesVtbl,

	ActivateObject: proc "system" (this: rawptr, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	ShutdownObject: proc "system" (this: rawptr) -> HRESULT,
	DetachObject:   proc "system" (this: rawptr) -> HRESULT,
}
IMFActivate :: struct { vtbl: ^IMFActivateVtbl }

IMFMediaBufferVtbl :: struct {
	QueryInterface: proc "system" (this: rawptr, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	AddRef:         proc "system" (this: rawptr) -> u32,
	Release:        proc "system" (this: rawptr) -> u32,
	Lock:           proc "system" (this: rawptr, buf: ^^u8, maxLen: ^u32, curLen: ^u32) -> HRESULT,
	Unlock:         proc "system" (this: rawptr) -> HRESULT,
	GetCurrentLength:  proc "system" (this: rawptr, curLen: ^u32) -> HRESULT,
	SetCurrentLength:  proc "system" (this: rawptr, curLen: u32) -> HRESULT,
	GetMaxLength:      proc "system" (this: rawptr, maxLen: ^u32) -> HRESULT,
}
IMFMediaBuffer :: struct { vtbl: ^IMFMediaBufferVtbl }

IMFSampleVtbl :: struct {
	using _: IMFAttributesVtbl,

	GetSampleFlags:   proc "system" (this: rawptr, flags: ^u32) -> HRESULT,
	SetSampleFlags:   proc "system" (this: rawptr, flags: u32) -> HRESULT,
	GetSampleTime:    proc "system" (this: rawptr, time: ^i64) -> HRESULT,
	SetSampleTime:    proc "system" (this: rawptr, time: i64) -> HRESULT,
	GetSampleDuration: proc "system" (this: rawptr, dur: ^i64) -> HRESULT,
	SetSampleDuration: proc "system" (this: rawptr, dur: i64) -> HRESULT,
	GetBufferCount:   proc "system" (this: rawptr, count: ^u32) -> HRESULT,
	GetBufferByIndex: proc "system" (this: rawptr, index: u32, buf: ^^IMFMediaBuffer) -> HRESULT,
	ConvertToContiguousBuffer: proc "system" (this: rawptr, buf: ^^IMFMediaBuffer) -> HRESULT,
	AddBuffer:        proc "system" (this: rawptr, buf: ^IMFMediaBuffer) -> HRESULT,
	RemoveBufferByIndex: proc "system" (this: rawptr, index: u32) -> HRESULT,
	RemoveAllBuffers: proc "system" (this: rawptr) -> HRESULT,
	GetTotalLength:   proc "system" (this: rawptr, len: ^u32) -> HRESULT,
	CopyToBuffer:     proc "system" (this: rawptr, buf: ^IMFMediaBuffer) -> HRESULT,
}
IMFSample :: struct { vtbl: ^IMFSampleVtbl }

IMFSourceReaderVtbl :: struct {
	QueryInterface: proc "system" (this: rawptr, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	AddRef:         proc "system" (this: rawptr) -> u32,
	Release:        proc "system" (this: rawptr) -> u32,
	GetStreamSelection:      proc "system" (this: rawptr, si: u32, sel: ^BOOL) -> HRESULT,
	SetStreamSelection:      proc "system" (this: rawptr, si: u32, sel: BOOL) -> HRESULT,
	GetNativeMediaType:      proc "system" (this: rawptr, si: u32, mi: u32, mt: ^rawptr) -> HRESULT,
	GetCurrentMediaType:     proc "system" (this: rawptr, si: u32, mt: ^rawptr) -> HRESULT,
	SetCurrentMediaType:     proc "system" (this: rawptr, si: u32, reserved: ^u32, mt: rawptr) -> HRESULT,
	SetCurrentPosition:      proc "system" (this: rawptr, fmt: ^GUID, pos: rawptr) -> HRESULT,
	ReadSample:              proc "system" (this: rawptr, si: u32, flags: u32, asi: ^u32, f: ^u32, ts: ^i64, s: ^rawptr) -> HRESULT,
	Flush:                   proc "system" (this: rawptr, si: u32) -> HRESULT,
	GetServiceForStream:     proc "system" (this: rawptr, si: u32, svc: ^GUID, riid: ^GUID, ppv: ^rawptr) -> HRESULT,
	GetPresentationAttribute: proc "system" (this: rawptr, si: u32, attr: ^GUID, val: rawptr) -> HRESULT,
}
IMFSourceReader :: struct { vtbl: ^IMFSourceReaderVtbl }

var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE := &GUID{0xc60ac5fe, 0x252a, 0x478f, {0xa0, 0xef, 0xbc, 0x8f, 0xa5, 0xf7, 0xca, 0xd3}}
var_MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP := &GUID{0x8ac3587a, 0x4ae7, 0x42d8, {0x99, 0xe0, 0x0a, 0x60, 0x13, 0xee, 0xf9, 0x0f}}
var_MF_MT_MAJOR_TYPE   := &GUID{0x48eba18e, 0xf8c9, 0x4687, {0xbf, 0x11, 0x0a, 0x74, 0xc9, 0xf9, 0x6a, 0x8f}}
var_MF_MT_SUBTYPE      := &GUID{0xf7e34c9a, 0x42e8, 0x4714, {0xb7, 0x4b, 0xcb, 0x29, 0xd7, 0x2c, 0x35, 0xe5}}
var_MF_MT_FRAME_SIZE   := &GUID{0x1652c33d, 0xd6b2, 0x4012, {0xb8, 0x34, 0x72, 0x03, 0x08, 0x49, 0xa3, 0x7d}}
var_MF_MT_INTERLACE_MODE := &GUID{0xe2724fc1, 0x364, 0x4b3c, {0x9c, 0x1f, 0x57, 0x33, 0x19, 0x86, 0x4, 0x73}}
var_MFMediaType_Video  := &GUID{0x73646976, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71}}
var_MFVideoFormat_RGB32 := &GUID{0x00000016, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71}}
var_MFVideoFormat_NV12 := &GUID{0x3231564e, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71}}
var_IID_IMFMediaSource := &GUID{0x279a808d, 0xaec7, 0x40c8, {0x9c, 0x6b, 0xa6, 0xb4, 0x92, 0xc7, 0x8a, 0x66}}
var_MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING := &GUID{0xfb394f3d, 0xccf1, 0x42ee, {0xbb, 0xb3, 0xf9, 0xb8, 0x45, 0xd5, 0x68, 0x1d}}

MF_SOURCE_READER_FIRST_VIDEO_STREAM :: 0xFFFFFFFC
MF_SOURCE_READERF_ERROR        :: 0x00000001
MF_SOURCE_READERF_ENDOFSTREAM  :: 0x00000002
MF_SOURCE_READERF_NATIVEMEDIATYPECHANGED :: 0x00000010
MFSTARTUP_NOSOCKET :: 0x00000001
MF_API_VERSION     :: 0x10070

foreign import mfplat_dll "system:mfplat.lib"
foreign import mf_dll "system:mf.lib"
foreign import mfreadwrite_dll "system:mfreadwrite.lib"
foreign import ole32_dll "system:ole32.lib"

foreign mfplat_dll {
	MFStartup           :: proc "system" (v: u32, f: u32) -> HRESULT ---
	MFShutdown          :: proc "system" () -> HRESULT ---
	MFCreateAttributes  :: proc "system" (a: ^^IMFAttributes, c: u32) -> HRESULT ---
	MFCreateMediaType   :: proc "system" (mt: ^rawptr) -> HRESULT ---
}

foreign ole32_dll {
	CoTaskMemFree       :: proc "system" (pv: rawptr) ---
}

foreign mf_dll {
	MFEnumDeviceSources :: proc "system" (a: ^IMFAttributes, d: rawptr, c: ^u32) -> HRESULT ---
}

foreign mfreadwrite_dll {
	MFCreateSourceReaderFromMediaSource :: proc "system" (s: rawptr, a: ^IMFAttributes, r: ^^IMFSourceReader) -> HRESULT ---
}

Camera :: struct {
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

camera_init :: proc(cam: ^Camera, device_index: u32) -> bool {
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

camera_read_frame :: proc(cam: ^Camera) -> ([]u8, bool) {
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

camera_destroy :: proc(cam: ^Camera) {
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
