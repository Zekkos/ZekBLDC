const std = @import("std");


// Fixed point layout is +/-15.16
// All operations will overflow and will not return an error
const fixed32_decimal: i32 = 16;
pub const Fixed32 = struct {
    number: i32,

    // Initilise Fixed32 using a floating point number
    pub fn init_float(fnumber: f32) Fixed32 {
        return Fixed32 {
            .number = @intFromFloat(fnumber * std.math.pow(f32, 2, fixed32_decimal)),
        };
    }

    pub fn get_float(self: Fixed32) f32 {
        const f_number: f32 = @floatFromInt(self.number);
        return f_number / std.math.pow(f32, 2, fixed32_decimal);
    }

    //  Fixed point addition
    pub fn add(self: Fixed32, other: Fixed32) Fixed32 {  
        return Fixed32 {.number = self.number +% other.number};
    }

    // Fixed point subtraction
    pub fn sub(self: Fixed32, other: Fixed32) Fixed32 {
        return Fixed32 {.number = self.number -% other.number};
    }

    // Fixed point multiplication
    pub fn mult(self: Fixed32, other: Fixed32) Fixed32 {
        const self_temp: i64 = self.number;
        const other_temp: i64 = other.number;

        return Fixed32 { .number = @intCast((self_temp *% other_temp) >> fixed32_decimal)};
    }

    // Fixed point division
    // WARNING: Slow AF in comparison
    pub fn div(self: Fixed32, other: Fixed32) Fixed32 {
        const self_temp: i64 = self.number;
        const other_temp: i64 = other.number;

        return Fixed32 { .number = @intCast(@divFloor(self_temp << (32 - fixed32_decimal), other_temp))};
    }

    pub fn neg(self: Fixed32) Fixed32 {
        return Fixed32 {.number = -self.number};
    }

    pub fn sin(self: Fixed32) Fixed32 {
        // Reduce size of self until -pi/2 >= x <= pi/2 as approximation only works in that range
        var number_of_steps: i32 = 0;
        const is_pos: bool = self.number > 0;
        var tracked_num = self;

        if(!is_pos) {
            tracked_num.number = -tracked_num.number;
        }

        const pi_over_2 = comptime Fixed32.init_float(std.math.pi / 2.0);
        const pi = comptime Fixed32.init_float(std.math.pi);
        const pi_2 = comptime Fixed32.init_float(2.0 * std.math.pi);
        const pi_3_over_4 = comptime Fixed32.init_float((3.0 * std.math.pi) / 2.0);

        while ( tracked_num.number > pi_3_over_4.number) : (tracked_num = tracked_num.sub(pi_2)) {
            number_of_steps += 1;
        }

        const three_factorial = comptime Fixed32.init_float(1.0 / (3.0 * 2.0));
        const five_factorial = comptime Fixed32.init_float(1.0 / (5.0 * 4.0 * 3.0 * 2.0));

        var temp = tracked_num;
        if (tracked_num.number > pi_over_2.number) {
            temp = temp.neg().add(pi); 
        }
        const num_pow_3 = temp.mult(temp).mult(temp);
        const num_pow_5 = num_pow_3.mult(temp).mult(temp);
        const sine_out = temp.sub(num_pow_3.mult(three_factorial)).add(num_pow_5.mult(five_factorial));

        return sine_out;
    }
    
    pub fn cos(self: Fixed32) Fixed32 {
        const pi_over_2 = comptime Fixed32.init_float(std.math.pi / 2.0);
        const temp = self.add(pi_over_2);

        return temp.sin();
    }

};

pub const Fixed32Vec2D = struct {
    x: Fixed32,
    y: Fixed32,

    pub fn clarke_transform_simple(self: Fixed32Vec2D) Fixed32Vec2D {
        const one_over_root_3 = comptime Fixed32.init_float(1.0 / (std.math.sqrt(3.0)));
        const two_over_root_3 = comptime Fixed32.init_float(2.0 / (std.math.sqrt(3.0)));

        return Fixed32Vec2D {
            .x = self.x,
            .y = self.x.mult(one_over_root_3).add(self.y.mult(two_over_root_3)),
        };
    }

    pub fn inv_clarke_transform_simple(self: Fixed32Vec2D) Fixed32Vec2D {
        const root_three_over_two = comptime Fixed32.init_float(std.math.sqrt(3.0) / 2.0);
        const one_half = comptime Fixed32.init_float(0.5);

        return Fixed32Vec2D {
            .x = self.x,
            .y = one_half.neg().mult(self.x).add(root_three_over_two.mult(self.y)),
        };
    }

    pub fn park_transform(self: Fixed32Vec2D, angle: Fixed32) Fixed32Vec2D {
        const cos_theta = angle.cos();
        const sin_theta = angle.sin();

        return Fixed32Vec2D {
            .x = cos_theta.mult(self.x).add(sin_theta.mult(self.y)),
            .y = sin_theta.neg().mult(self.x).add(cos_theta.mult(self.y)),
        };
    }

    pub fn inv_park_transform(self: Fixed32Vec2D, angle: Fixed32) Fixed32Vec2D {
        const cos_theta = angle.cos();
        const sin_theta = angle.sin();

        return Fixed32Vec2D {
            .x = cos_theta.mult(self.x).add(sin_theta.neg().mult(self.y)),
            .y = sin_theta.mult(self.x).add(cos_theta.mult(self.y)),
        };
    }

};

const expect = std.testing.expect;
test "conversion test" {
    const testFixed32 = Fixed32.init_float(10.0);
    try expect(testFixed32.get_float() == 10.0); 
}

test "addition test" {
    const test_fixed32 = Fixed32.init_float(10.0);
    const test2_fixed32 = Fixed32.init_float(10.0);
    const test3_fixed32 = test_fixed32.add(test2_fixed32);

    try expect(test3_fixed32.get_float() == 20.0);
}

test "subtract test" {
    const test_fixed32 = Fixed32.init_float(10.0);
    const test2_fixed32 = Fixed32.init_float(5.0);
    const test3_fixed32 = test_fixed32.sub(test2_fixed32);

    try expect(test3_fixed32.get_float() == 5.0);
}

test "mult test" {
    var test_fixed32 = Fixed32.init_float(10.0);
    const test2_fixed32 = Fixed32.init_float(5.0);
    const test3_fixed32 = test_fixed32.mult(test2_fixed32);

    try expect(test3_fixed32.get_float() == 50.0);
}

test "div test" {
    const test_fixed32 = Fixed32.init_float(10.0);
    const test2_fixed32 = Fixed32.init_float(20.0);
    const test3_fixed32 = test_fixed32.div(test2_fixed32);

    try expect(test3_fixed32.get_float() == 0.5);
}

fn close_enough_check(val: f32, target: f32, allowed_err: f32) bool {
    return @abs(val - target) < allowed_err;
}

test "sine consine check" {
    const error_limit: f32 = 0.005;
    const float_vals = [_]f32{0.0, 1.0, std.math.pi / 2.0, 100.0, 3.0, 4.5, 1.0, 3.0, 4.0, 5.0, 6.0, 7.0};

    for (0..float_vals.len) |i| {
        const fixed_sine = Fixed32.init_float(float_vals[i]).sin();
        const actual_sine = std.math.sin(float_vals[i]);
        if (!close_enough_check(actual_sine, fixed_sine.get_float(), error_limit)){
            std.debug.print("Test Failed {}:\n    actual_sine={}\n    fixed_sine={}\n", .{i, actual_sine, fixed_sine.get_float()});
            try expect(false);
        }
    }
    for (0..float_vals.len) |i| {
        const fixed_sine = Fixed32.init_float(float_vals[i]).cos();
        const actual_sine = std.math.cos(float_vals[i]);
        if (!close_enough_check(actual_sine, fixed_sine.get_float(), error_limit)){
            std.debug.print("Test Failed {}:\n    actual_cosine={}\n    fixed_cosine={}\n", .{i, actual_sine, fixed_sine.get_float()});
            try expect(false);
        }
    }
}
