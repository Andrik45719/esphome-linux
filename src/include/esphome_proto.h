/**
 * @file esphome_proto.h
 * @brief Minimal protobuf encoding/decoding for ESPHome Native API
 *
 * This is a lightweight implementation focused on the specific messages
 * needed for ESPHome Bluetooth Proxy functionality.
 */

#ifndef ESPHOME_PROTO_H
#define ESPHOME_PROTO_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* ESPHome API Message Types */
#define ESPHOME_MSG_HELLO_REQUEST                                1
#define ESPHOME_MSG_HELLO_RESPONSE                               2
#define ESPHOME_MSG_CONNECT_REQUEST                              3
#define ESPHOME_MSG_CONNECT_RESPONSE                             4
#define ESPHOME_MSG_DISCONNECT_REQUEST                           5
#define ESPHOME_MSG_DISCONNECT_RESPONSE                          6
#define ESPHOME_MSG_PING_REQUEST                                 7
#define ESPHOME_MSG_PING_RESPONSE                                8
#define ESPHOME_MSG_DEVICE_INFO_REQUEST                          9
#define ESPHOME_MSG_DEVICE_INFO_RESPONSE                        10
#define ESPHOME_MSG_LIST_ENTITIES_REQUEST                       11
#define ESPHOME_MSG_LIST_ENTITIES_DONE_RESPONSE                 19
#define ESPHOME_MSG_SUBSCRIBE_STATES_REQUEST                    20
#define ESPHOME_MSG_SUBSCRIBE_HOMEASSISTANT_SERVICES_REQUEST    34
#define ESPHOME_MSG_SUBSCRIBE_HOMEASSISTANT_STATES_REQUEST      38
#define ESPHOME_MSG_SUBSCRIBE_BLUETOOTH_LE_ADVERTISEMENTS_REQUEST  66
#define ESPHOME_MSG_BLUETOOTH_LE_RAW_ADVERTISEMENTS_RESPONSE     93

/* Maximum sizes */
#define ESPHOME_MAX_STRING_LEN     128
#define ESPHOME_MAX_ADV_DATA       62   /* BLE spec: 31 + 31 */
#define ESPHOME_MAX_ADV_BATCH      16
#define ESPHOME_MAX_MESSAGE_SIZE   4096

/* Protobuf wire types */
#define PB_WIRE_TYPE_VARINT    0
#define PB_WIRE_TYPE_64BIT     1
#define PB_WIRE_TYPE_LENGTH    2
#define PB_WIRE_TYPE_32BIT     5

/* Helper macros */
#define PB_FIELD_TAG(field_num, wire_type) (((field_num) << 3) | (wire_type))

/**
 * Protobuf encoder/decoder buffer
 */
typedef struct {
    uint8_t *data;      /* Buffer pointer */
    size_t size;        /* Buffer size */
    size_t pos;         /* Current position */
    bool error;         /* Error flag */
} pb_buffer_t;

/**
 * ESPHome message structures (minimal, only fields we use)
 */

typedef struct {
    char client[ESPHOME_MAX_STRING_LEN];
} esphome_hello_request_t;

typedef struct {
    uint32_t api_version_major;      /* Field 1 - uint32 */
    uint32_t api_version_minor;      /* Field 2 - uint32 */
    char server_info[ESPHOME_MAX_STRING_LEN];
    char name[ESPHOME_MAX_STRING_LEN];
} esphome_hello_response_t;

typedef struct {
    char password[ESPHOME_MAX_STRING_LEN];
} esphome_connect_request_t;

typedef struct {
    bool invalid_password;
} esphome_connect_response_t;

typedef struct {
    /* Empty */
} esphome_device_info_request_t;

/* Bluetooth Proxy Feature Flags (bitfield) */
#define BLE_FEATURE_PASSIVE_SCAN      (1 << 0)  /* Passive BLE scanning */
#define BLE_FEATURE_ACTIVE_SCAN       (1 << 1)  /* Active BLE scanning */
#define BLE_FEATURE_REMOTE_CACHE      (1 << 2)  /* Remote caching */
#define BLE_FEATURE_PAIRING           (1 << 3)  /* BLE pairing */
#define BLE_FEATURE_CACHE_CLEARING    (1 << 4)  /* Cache clearing */
#define BLE_FEATURE_RAW_ADVERTISEMENTS (1 << 5)  /* Raw advertisement data */

typedef struct {
    bool uses_password;
    char name[ESPHOME_MAX_STRING_LEN];
    char mac_address[24];
    char esphome_version[32];
    char compilation_time[64];
    char model[ESPHOME_MAX_STRING_LEN];
    char manufacturer[ESPHOME_MAX_STRING_LEN];
    char friendly_name[ESPHOME_MAX_STRING_LEN];
    bool has_deep_sleep;
    char suggested_area[64];
    uint32_t bluetooth_proxy_feature_flags;  /* Field 15 - BLE proxy capabilities */
    char bluetooth_mac_address[24];          /* Field 18 - Bluetooth MAC address */
} esphome_device_info_response_t;

typedef struct {
    /* Empty */
} esphome_list_entities_request_t;

typedef struct {
    /* Empty */
} esphome_list_entities_done_t;

typedef struct {
    uint32_t flags;
} esphome_subscribe_ble_advertisements_t;

typedef struct {
    uint64_t address;           /* BLE MAC address (little-endian uint64) */
    int32_t rssi;              /* Signal strength */
    uint32_t address_type;     /* 0=public, 1=random */
    uint8_t data[ESPHOME_MAX_ADV_DATA];
    size_t data_len;
} esphome_ble_advertisement_t;

typedef struct {
    esphome_ble_advertisement_t advertisements[ESPHOME_MAX_ADV_BATCH];
    size_t count;
} esphome_ble_advertisements_response_t;

/**
 * Protobuf encoding functions
 */

/* Initialize buffer for writing */
void pb_buffer_init_write(pb_buffer_t *buf, uint8_t *data, size_t size);

/* Initialize buffer for reading */
void pb_buffer_init_read(pb_buffer_t *buf, const uint8_t *data, size_t size);

/* Encode varint */
bool pb_encode_varint(pb_buffer_t *buf, uint64_t value);

/* Encode string */
bool pb_encode_string(pb_buffer_t *buf, uint32_t field_num, const char *str);

/* Encode bool */
bool pb_encode_bool(pb_buffer_t *buf, uint32_t field_num, bool value);

/* Encode fixed64 */
bool pb_encode_fixed64(pb_buffer_t *buf, uint32_t field_num, uint64_t value);

/* Encode uint64 (varint) */
bool pb_encode_uint64(pb_buffer_t *buf, uint32_t field_num, uint64_t value);

/* Encode sint32 (zigzag encoding) */
bool pb_encode_sint32(pb_buffer_t *buf, uint32_t field_num, int32_t value);

/* Encode uint32 */
bool pb_encode_uint32(pb_buffer_t *buf, uint32_t field_num, uint32_t value);

/* Encode bytes */
bool pb_encode_bytes(pb_buffer_t *buf, uint32_t field_num, const uint8_t *data, size_t len);

/* Decode varint */
bool pb_decode_varint(pb_buffer_t *buf, uint64_t *value);

/* Decode string */
bool pb_decode_string(pb_buffer_t *buf, char *str, size_t max_len);

/* Decode uint32 */
bool pb_decode_uint32(pb_buffer_t *buf, uint32_t *value);

/* Skip field */
bool pb_skip_field(pb_buffer_t *buf, uint8_t wire_type);

/**
 * ESPHome message encoding
 */

size_t esphome_encode_hello_response(uint8_t *buf, size_t size,
                                      const esphome_hello_response_t *msg);

size_t esphome_encode_connect_response(uint8_t *buf, size_t size,
                                        const esphome_connect_response_t *msg);

size_t esphome_encode_device_info_response(uint8_t *buf, size_t size,
                                            const esphome_device_info_response_t *msg);

size_t esphome_encode_list_entities_done(uint8_t *buf, size_t size);

size_t esphome_encode_ble_advertisements(uint8_t *buf, size_t size,
                                          const esphome_ble_advertisements_response_t *msg);

/**
 * ESPHome message decoding
 */

bool esphome_decode_hello_request(const uint8_t *buf, size_t size,
                                   esphome_hello_request_t *msg);

bool esphome_decode_connect_request(const uint8_t *buf, size_t size,
                                     esphome_connect_request_t *msg);

bool esphome_decode_subscribe_ble_advertisements(const uint8_t *buf, size_t size,
                                                  esphome_subscribe_ble_advertisements_t *msg);

/**
 * ESPHome message framing
 */

/* Encode message with framing (length + type + payload) */
size_t esphome_frame_message(uint8_t *out_buf, size_t out_size,
                              uint16_t msg_type,
                              const uint8_t *payload, size_t payload_len);

/* Decode message header (returns payload offset, or 0 on error) */
size_t esphome_decode_frame_header(const uint8_t *buf, size_t size,
                                    uint32_t *msg_len, uint16_t *msg_type);

#endif /* ESPHOME_PROTO_H */
