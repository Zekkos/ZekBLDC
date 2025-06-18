const Fixed32 = @import("fixed_point.zig").Fixed32;
const math = @import("std").math;

const SpaceVectorStateError = error{
    BadDutyCycle,
    BadAngle,
};

pub const SpaceVectorState = struct {
    a_period: Fixed32,
    b_period: Fixed32,
    c_period: Fixed32,

    // Assumes 0 is inline with A direction and is postive in the counter clockswise direciton
    pub fn get_periods_at_commutation_angle(angle: Fixed32,
                                            duty_cycle: Fixed32) !SpaceVectorState {
    
        // Comptime constants
        const sixth_of_rotation = comptime Fixed32.init_float(2.0 * math.pi / 6.0);
        const one = comptime Fixed32.init_float(1.0);
        const half_one = comptime Fixed32.init_float(0.5);
        const two_pi = comptime Fixed32.init_float(2.0 * math.pi);
        const segments: [6]Fixed32 = comptime .{
            Fixed32.init_float(2.0 * math.pi / 6.0 * 1.0),
            Fixed32.init_float(2.0 * math.pi / 6.0 * 2.0),
            Fixed32.init_float(2.0 * math.pi / 6.0 * 3.0),
            Fixed32.init_float(2.0 * math.pi / 6.0 * 4.0),
            Fixed32.init_float(2.0 * math.pi / 6.0 * 5.0),
            Fixed32.init_float(2.0 * math.pi / 6.0 * 6.0)
        };
        
        // Handle bad inputs
        if (duty_cycle.number > one.number or duty_cycle.number < 0) { return SpaceVectorStateError.BadDutyCycle; }
        if (angle.number > two_pi.number or angle.number < 0) { return SpaceVectorStateError.BadAngle; }


        // Caculate and return duty cycle high times as 0-1 values for each line
        const t1 = duty_cycle.mult(sixth_of_rotation.sub(angle).sin());
        const t2 = duty_cycle.mult(angle.sin());
        const t0 = one.sub(t1).sub(t2);

        const t0_half = t0.mult(half_one);

        if (angle.number < segments[0].number) {
            return SpaceVectorState {.a_period = t0_half, .b_period = t0_half.add(t1), .c_period = t0_half.add(t1).add(t2)};
        } else if (angle.number < segments[1].number) {
            return SpaceVectorState {.a_period = t0_half.add(t2), .b_period = t0_half, .c_period = t0_half.add(t1).add(t2)};
        } else if (angle.number < segments[2].number) {
            return SpaceVectorState {.a_period = t0_half.add(t1).add(t2), .b_period = t0_half, .c_period = t0_half.add(t1)};
        } else if (angle.number < segments[3].number) {
            return SpaceVectorState {.a_period = t0_half.add(t1).add(t2), .b_period = t0_half.add(t2), .c_period = t0_half};
        } else if (angle.number < segments[4].number) {
            return SpaceVectorState {.a_period = t0_half.add(t1), .b_period = t0_half.add(t1).add(t2), .c_period = t0_half};
        } else {
            return SpaceVectorState {.a_period = t0_half, .b_period = t0_half.add(t1).add(t2), .c_period = t0_half.add(t2)};
        }
    }
};

const expect = @import("std").testing.expect;
test "Space Vector State error checks" {
    try expect(SpaceVectorState.get_periods_at_commutation_angle(Fixed32.init_float(0.5), Fixed32.init_float(1.2)) == SpaceVectorStateError.BadDutyCycle);
    try expect(SpaceVectorState.get_periods_at_commutation_angle(Fixed32.init_float(7.0), Fixed32.init_float(0.5)) == SpaceVectorStateError.BadAngle);
    try expect(SpaceVectorState.get_periods_at_commutation_angle(Fixed32.init_float(0.5), Fixed32.init_float(-0.1)) == SpaceVectorStateError.BadDutyCycle);
    try expect(SpaceVectorState.get_periods_at_commutation_angle(Fixed32.init_float(-0.1), Fixed32.init_float(0.2)) == SpaceVectorStateError.BadAngle);
}
