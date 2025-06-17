const std = @import("std");
const microzig = @import("microzig");
const Fixed32 = @import("fixed_point.zig").Fixed32;

const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const usb = rp2xxx.usb;

const usb_dev = rp2xxx.usb.Usb(.{});
const usb_config_len = usb.templates.config_descriptor_len + usb.templates.cdc_descriptor_len;
const usb_config_descriptor = 
    usb.templates.config_descriptor(1, 2, 0, usb_config_len, 0xc0, 100) ++
    usb.templates.cdc_descriptor(0, 4, usb.Endpoint.to_address(1, .In), 8, usb.Endpoint.to_address(2, .Out), usb.Endpoint.to_address(2, .In), 64);

var driver_cdc: usb.cdc.CdcClassDriver(usb_dev) = .{};
var drivers = [_]usb.types.UsbClassDriver{driver_cdc.driver()};

// USB Device Configuration
pub var DEVICE_CONFIG: usb.DeviceConfiguration = .{
    .device_descriptor = &.{
        .descriptor_type = usb.DescType.Device,
        .bcd_usb = 0x0200,
        .device_class = 0xEF,
        .device_subclass = 2,
        .device_protocol = 1,
        .max_packet_size0 = 64,
        .vendor = 0x2E8A,
        .product = 0x000a,
        .bcd_device = 0x0100,
        .manufacturer_s = 1,
        .product_s = 2,
        .serial_s = 0,
        .num_configurations = 1,
    },
    .config_descriptor = &usb_config_descriptor,
    .lang_descriptor = "\x04\x03\x09\x04",
    .descriptor_strings = &.{
        &usb.utils.utf8ToUtf16Le("Raspberry Pi"),
        &usb.utils.utf8ToUtf16Le("Pico Test Device"),
        &usb.utils.utf8ToUtf16Le("someserial"),
        &usb.utils.utf8ToUtf16Le("Board CDC"),
    },
    .drivers = &drivers,
};

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    std.log.err("panic: {s}", .{message});
    @breakpoint();
    while(true) {}
}



// Compile-time pin configuration
const pin_config = rp2xxx.pins.GlobalConfiguration{
    .GPIO25 = .{
        .name = "led",
        .direction = .out,
    },
};

const pins = pin_config.pins();

const fixed_pi = Fixed32.init_float(3.141);

pub fn main() !noreturn {
    pin_config.apply();

    usb_dev.init_clk();
    usb_dev.init_device(&DEVICE_CONFIG) catch unreachable;

    while (true) {
        pins.led.toggle();
        time.sleep_ms(250);
    }
}
