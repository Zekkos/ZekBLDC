const Fixed32 = @import("fixed_point.zig").Fixed32;

const FixedPID = struct {
    kp: Fixed32,
    ki: Fixed32,
    kd: Fixed32,

    err_prev: Fixed32,
    i_sum: Fixed32,
    
    i_err_upper_limit: Fixed32,
    i_err_lower_limit: Fixed32,
    i_err_limit_active: bool = false,

    pub fn init(kp: Fixed32, ki: Fixed32, kd: Fixed32) FixedPID {
        return FixedPID {.kp = kp, .ki = ki, .kd = kd, .i_sum = 0, .err_prev = 0 };
    }

    pub fn set_intergral_error_limits(self: *FixedPID, lower_limit: Fixed32, upper_limit: Fixed32) void {
        self.i_err_lower_limit = lower_limit;
        self.i_err_upper_limit = upper_limit;
        self.i_err_limit_active = true;
    }

    pub fn update(self: *FixedPID, err: Fixed32, delta_t: Fixed32) Fixed32 {
        const kd_val = self.err_prev.sub(err).mult(self.kd);
        self.i_sum = self.i_sum.add(err.mult(delta_t));
        if (self.i_err_limit_active) {
            if (err.number < self.i_err_lower_limit.number or err.number > self.i_err_upper_limit.number){
                self.i_sum = Fixed32 {.number = 0};
            }
        }
        const ki_val = self.i_sum.mult(self.ki);
        return self.kp.mult(err).add(kd_val).add(ki_val);
    }
};
