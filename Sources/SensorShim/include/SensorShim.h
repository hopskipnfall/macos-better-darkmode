#ifndef SENSOR_SHIM_H
#define SENSOR_SHIM_H

int sensor_service_count(void);
double sensor_read_field(int index);
int lid_is_closed(void);

#endif
