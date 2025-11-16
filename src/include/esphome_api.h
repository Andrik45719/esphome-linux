/**
 * @file esphome_api.h
 * @brief ESPHome Native API Server
 *
 * Implements the ESPHome Native API protocol over TCP for
 * Bluetooth Proxy functionality.
 */

#ifndef ESPHOME_API_H
#define ESPHOME_API_H

#include <stdint.h>
#include <stdbool.h>
#include <pthread.h>

/* Server configuration */
#define ESPHOME_API_PORT 6053
#define ESPHOME_MAX_CLIENTS 2

/**
 * Device configuration
 */
typedef struct {
    char device_name[128];
    char mac_address[24];         /* "AA:BB:CC:DD:EE:FF" */
    char esphome_version[32];
    char model[128];
    char manufacturer[128];
    char friendly_name[128];
    char suggested_area[64];
} esphome_device_config_t;

/**
 * BLE advertisement (matches ble_scanner.h structure)
 */
typedef struct {
    uint8_t address[6];          /* BLE MAC address */
    uint8_t address_type;        /* 0=public, 1=random */
    int8_t rssi;                 /* Signal strength */
    uint8_t data[62];            /* Combined adv + scan response */
    size_t data_len;
} esphome_ble_advert_t;

/**
 * API server instance
 */
typedef struct esphome_api_server esphome_api_server_t;

/**
 * Initialize the API server
 *
 * @param config Device configuration
 * @return Server instance, or NULL on error
 */
esphome_api_server_t *esphome_api_init(const esphome_device_config_t *config);

/**
 * Start the API server (non-blocking)
 *
 * Starts a background thread to handle TCP connections.
 *
 * @param server Server instance
 * @return 0 on success, -1 on error
 */
int esphome_api_start(esphome_api_server_t *server);

/**
 * Stop the API server
 *
 * @param server Server instance
 */
void esphome_api_stop(esphome_api_server_t *server);

/**
 * Free the API server
 *
 * @param server Server instance
 */
void esphome_api_free(esphome_api_server_t *server);

/**
 * Queue a BLE advertisement for sending
 *
 * Advertisements are batched and sent periodically to connected clients.
 *
 * @param server Server instance
 * @param advert Advertisement data
 */
void esphome_api_queue_ble_advert(esphome_api_server_t *server,
                                  const esphome_ble_advert_t *advert);

#endif /* ESPHOME_API_H */
