package camera

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




