/*
 * JANUS VCOM public control protocol.
 *
 * This header is shared conceptually by janus-vcom.sys and Rust Core's
 * core/src/windows_vcom.rs. It deliberately contains no third-party driver
 * ABI, so JANUS owns versioning and pair lifecycle end to end.
 */

#pragma once

/* The same wire layout is consumed by user mode and KMDF.  Pulling UM's
 * winioctl.h into a kernel compilation conflicts with wdm.h definitions. */
#if defined(_NTDDK_)
#include <wdm.h>
#else
#include <winioctl.h>
#endif

#define JANUS_VCOM_PROTOCOL_VERSION 1u
#define JANUS_VCOM_PORT_NAME_CHARS 16u

/* Private device type allocated for JANUS's control device. */
#define FILE_DEVICE_JANUS_VCOM 0x8337u

#define IOCTL_JANUS_VCOM_CREATE_PAIR \
    CTL_CODE(FILE_DEVICE_JANUS_VCOM, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_JANUS_VCOM_DELETE_PAIR \
    CTL_CODE(FILE_DEVICE_JANUS_VCOM, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_JANUS_VCOM_ENUMERATE_PAIRS \
    CTL_CODE(FILE_DEVICE_JANUS_VCOM, 0x802, METHOD_BUFFERED, FILE_ANY_ACCESS)

typedef struct _JANUS_VCOM_CREATE_PAIR_REQUEST {
    ULONG Version;
    WCHAR ExternalPort[JANUS_VCOM_PORT_NAME_CHARS];
    WCHAR MonitorPort[JANUS_VCOM_PORT_NAME_CHARS];
} JANUS_VCOM_CREATE_PAIR_REQUEST, *PJANUS_VCOM_CREATE_PAIR_REQUEST;

typedef struct _JANUS_VCOM_DELETE_PAIR_REQUEST {
    ULONG Version;
    WCHAR ExternalPort[JANUS_VCOM_PORT_NAME_CHARS];
    WCHAR MonitorPort[JANUS_VCOM_PORT_NAME_CHARS];
} JANUS_VCOM_DELETE_PAIR_REQUEST, *PJANUS_VCOM_DELETE_PAIR_REQUEST;

typedef struct _JANUS_VCOM_PAIR_INFO {
    WCHAR ExternalPort[JANUS_VCOM_PORT_NAME_CHARS];
    WCHAR MonitorPort[JANUS_VCOM_PORT_NAME_CHARS];
    ULONG State;
    ULONG DroppedBytes;
} JANUS_VCOM_PAIR_INFO, *PJANUS_VCOM_PAIR_INFO;

/* Returned by ENUMERATE_PAIRS before an array of JANUS_VCOM_PAIR_INFO. */
typedef struct _JANUS_VCOM_ENUMERATE_PAIRS_RESPONSE {
    ULONG Version;
    ULONG PairCount;
} JANUS_VCOM_ENUMERATE_PAIRS_RESPONSE, *PJANUS_VCOM_ENUMERATE_PAIRS_RESPONSE;

typedef char JANUS_VCOM_CREATE_PAIR_LAYOUT_MUST_MATCH[
    sizeof(JANUS_VCOM_CREATE_PAIR_REQUEST) == 68 ? 1 : -1];
