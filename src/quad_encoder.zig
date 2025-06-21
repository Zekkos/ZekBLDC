const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const Pio = rp2xxx.pio.Pio;
const StateMachine = rp2xxx.pio.StateMachine;
const gpio = rp2xxx.gpio;

const quad_encoder_program = blk: {
    @setEvalBranchQuota(5000);
    break :blk rp2xxx.pio.assemble(
    \\.pio_version 0
    \\.program quad_encoder


    \\            ; All jumps following origin 0 is basically a look up table based on bits stored in the x register
    \\            ; Old New 00_00
    \\.origin 0
    \\    jmp nothing    ; 0000
    \\    jmp nothing    ; 0001
    \\    jmp nothing    ; 0010
    \\    jmp neg        ; 0011
    \\    jmp nothing    ; 0100
    \\    jmp nothing    ; 0101
    \\    jmp pos        ; 0110
    \\    jmp nothing    ; 0111
    \\    jmp nothing    ; 1000
    \\    jmp pos        ; 1001
    \\    jmp nothing    ; 1010
    \\    jmp nothing    ; 1011
    \\    jmp neg        ; 1100
    \\    jmp nothing    ; 1101
    \\    jmp nothing    ; 1110
    \\    jmp nothing    ; 1111

    \\.wrap_target
    \\PUBLIC begin:
    \\    
    \\        ; This block if run back to back will keep shifting in data into the ISR, which means MSB will have oldest data and LSB will have newest
    \\        ; Though this breaks the jmp by modifying PC, so isr needs to be cleaned first. Luckily the x register will still hold the previous state
    \\        ; of the encoder allowing us to keep the previous state
    \\    mov isr, null   ; Erase all old data
    \\    in x, 2         ; x register will have the previous encoder state in the LSB still
    \\    mov x, pins     ; Read pins into the first two bits of x
    \\    in x, 2         ; Push the new data into the LSB of the ISR
    \\    mov x, isr      ; Put all bits in the ISR into the x scratch register

    \\    mov pc, x       ; Now use the lookup table with the data stored in the x reigster to work out what change occured
    \\neg:
    \\    jmp y-- done    ; Subtract one and finish
    \\    jmp done        ; Handle case when previous jump isn't true because y is nothing
    \\nothing:
    \\    jmp begin        ; obv do nothing, not even gonna push data out because why bother? Might as well check for new info
    \\pos:
    \\    ; Right adding in pio is a bit cursed but here we go
    \\    mov y, !y       ; first we invert, e.g. so if the data stored was 12 its now -13
    \\    jmp y-- pos2    ; now we sub 1 so we looking at -14
    \\pos2:               ; have to use jump so this basically nullifies it
    \\    mov y, !y       ; this reverses the original invert going from -14 to 13. Succesfully incrementing by 1
    \\    ; Don't need the jmp to done here
    \\done:
    \\    mov isr, y      ; shove data in to ISR
    \\    push noblock    ; shove data out of ISR and make it someone else's problem (hint: future me)
    \\.wrap
    , .{}).get_program_by_name("quad_encoder");
};

const EncoderError = error {
    BadEncoderPins,
};

const Encoder = struct {
    encoder_pin_a: gpio,
    encoder_pin_b: gpio,

    encoder_ticks: i32,
    encoder_ticks_offset: i32,

    pub fn init (encoder_a: gpio, encoder_b: gpio) !Encoder {
        // TODO, actually setup pins and setup the pio interface  
        return Encoder {.encoder_pin_a = encoder_a, .encoder_pin_b = encoder_b};
    }

};
