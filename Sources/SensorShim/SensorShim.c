#include "SensorShim.h"
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>
#include <math.h>
#include <stdint.h>

// Private IOHIDEventSystem API (not in public headers). Declarations follow
// community documentation of the Apple Silicon ambient light sensor.
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
typedef struct __IOHIDEvent *IOHIDEventRef;

extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
extern int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
extern CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef client);
extern IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t timestamp);
extern double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

#define kIOHIDEventTypeAmbientLightSensor 12

static IOHIDEventSystemClientRef g_client = NULL;

static CFArrayRef copy_services(void) {
    if (!g_client) {
        g_client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        if (!g_client) return NULL;
        int page = 0xff00, usage = 4;
        CFNumberRef p = CFNumberCreate(NULL, kCFNumberIntType, &page);
        CFNumberRef u = CFNumberCreate(NULL, kCFNumberIntType, &usage);
        const void *keys[] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
        const void *vals[] = { p, u };
        CFDictionaryRef match = CFDictionaryCreate(NULL, keys, vals, 2,
            &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        IOHIDEventSystemClientSetMatching(g_client, match);
        CFRelease(match);
        CFRelease(p);
        CFRelease(u);
    }
    return IOHIDEventSystemClientCopyServices(g_client);
}

int sensor_service_count(void) {
    CFArrayRef services = copy_services();
    if (!services) return 0;
    int n = (int)CFArrayGetCount(services);
    CFRelease(services);
    return n;
}

double sensor_read_field(int index) {
    CFArrayRef services = copy_services();
    if (!services) return NAN;
    double result = NAN;
    if (CFArrayGetCount(services) > 0) {
        IOHIDServiceClientRef svc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, 0);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(svc, kIOHIDEventTypeAmbientLightSensor, 0, 0);
        if (event) {
            result = IOHIDEventGetFloatValue(event, (kIOHIDEventTypeAmbientLightSensor << 16) | index);
            CFRelease(event);
        }
    }
    CFRelease(services);
    return result;
}

int lid_is_closed(void) {
    io_service_t root = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"));
    if (!root) return 0;
    CFTypeRef v = IORegistryEntryCreateCFProperty(root, CFSTR("AppleClamshellState"), kCFAllocatorDefault, 0);
    int closed = (v == kCFBooleanTrue);
    if (v) CFRelease(v);
    IOObjectRelease(root);
    return closed;
}
