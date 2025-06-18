const Fixed32 = @import("fixed_point.zig").Fixed32;
const math = @import("std").math;


pub const SpaceVectorState = struct {
    a_period: Fixed32,
    b_period: Fixed32,
    c_period: Fixed32,

    // Assumes 0 is inline with A direction and is postive in the counter clockswise direciton
    pub fn get_periods_at_commutation_angle(angle: Fixed32,
                                            duty_cycle: Fixed32,
                                            counter_clockwise_rotation: bool) SpaceVectorState {
        const sixth_of_rotation = comptime Fixed32.init_float(2.0 * math.pi / 6.0);
        const one = comptime Fixed32.init_float(1.0);

        const t1 = duty_cycle.mult(sixth_of_rotation.sub(angle).sin());
        const t2 = duty_cycle.mult(angle.sin());
        const t0 = one.sub(t1).sub(t2);

        if (counter_clockwise_rotation) {
            
        }
    }
};




test "Check Space Vector State from angle is correct" {
    const test_struct = struct {
        angle: Fixed32,
        cc_dir: bool,
    };

    const tests: [10]test_struct = .{
        test_struct {.angle = Fixed32.init_float(0.01), .cc_dir = false},
        test_struct {.angle = Fixed32.init_float(0.01), .cc_dir = true},
    };
}
