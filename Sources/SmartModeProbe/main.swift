// Spike result (2026-10-08, M-series MBP): field 7 tracks ambient light (~6 in a dim room, ~280 under a lamp).
// Fields 1-4 are raw channels; field 0 is coarse. SmartMode uses field 7 as "lux".
import Foundation
import SensorShim

print("matching services:", sensor_service_count())
print("lid closed:", lid_is_closed())
print("sample  field0..field7  (cover the sensor / point at a lamp while this runs)")
for i in 0..<20 {
    let fields = (0..<8).map { String(format: "%10.3f", sensor_read_field(Int32($0))) }
    print(String(format: "%2d", i), fields.joined(separator: " "))
    Thread.sleep(forTimeInterval: 1)
}
