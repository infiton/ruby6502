# ruby6502

`ruby6502` is a Ruby wrapper around Mike Chambers' [fake6502](http://rubbermallet.org/fake6502.c). The `fake6502.c` code has been altered slightly to i.e. [properly handle](http://forum.6502.org/viewtopic.php?f=2&t=2052#p37758) binary coded decimal, [allow for](https://github.com/infiton/ruby6502/commit/496f63acdc6b7183562ed5dc14efa2b070dd201b#diff-72c56ac3de6eea5d8a3c62b0df1a017df2e7959acd3f8ece338beab525f63698R963-R968) interrupt requests to be masked, and other easy of use changes. See 6502.org [tutorials](http://www.6502.org/tutorials/) to learn more.

## Quick start

```ruby
require "ruby6502"

reset_vector = 0xfffc # address that 6502 reads to initialize program counter
program_org = 0x8000  # address where the program will be loaded

Ruby6502.load([
  program_org & 0xff, # least sig byte of program_org
  program_org >> 8,   # most sig byte of program_org
], location: reset_vector)

program = [
  0xa9, 0x01,         # LDA #$01
  0x18,               # CLC
  0x69, 0x02,         # ADC #$02
  0x8d, 0xfe, 0x11,   # STA $11fe
  0x69, 0x03,         # ADC #$03
  0x8d, 0xff, 0x11,   # STA $11ff
]

Ruby6502.load(program, location: program_org)

Ruby6502.reset
Ruby6502.program_counter # => 0x8000
Ruby6502.step_times(6) # execute 6 operations

Ruby6502.read(location: 0x11fe, bytes: 2)  # => [0x03, 0x06]
Ruby6502.a_register # => 0x06
Ruby6502.program_counter # => 0x800d
```

## Loading and reading memory

The `ruby6502` has a 64 Kb memory map that is directly addressable by the fake 6502. To load a `byte_array` to a memory address starting at `location` use:

```ruby
byte_array = [0x01, 0x02, 0x03]
location = 0x1000

Ruby6502.load(byte_array, location: location)
```

To read a number `bytes` starting at `location` use:

```
Ruby6502.read(location: location, bytes: 3) # => [0x01, 0x02, 0x03]
```

## Accessing 6502 internals

The following 6502 internals are accessible:

- `Ruby6502.program_counter`. This is initiailized after `Ruby6502.reset` to the 2 bytes located little endian at `0xfffc`.
- `Ruby6502.stack_pointer`. The stack is located between `0x100 - 0x1ff`. The stack pointer is initialized to `0xfd` after `Ruby6502.reset`.
- `Ruby6502.a_register`, `Ruby6502.x_register`, `Ruby6502.y_register`
- `Ruby6502.status_flags`. This is initialized to `0b0010000` after `Ruby6502.reset`.
- `Ruby6502.instruction_count` and `Ruby6502.tick_count` give the number of instructions and clock cycles that have elapsed since the last reset. Both values are initialized to `0` after `Ruby6502.reset`.



```ruby
Ruby6502.program_counter  # Initialized after calling Ruby
Ruby6502.stack_pointer
Ruby6502.a_register
```

## Running the 6502

The fake 6502 can be run forward by:

- `Ruby6502.step` will step the processor forward one operation.
- `Ruby6502.step_times(n)` will step the processor forward `n` operations.
- `Ruby6502.exec(ticks)` will step the processor forward up to `ticks` clock cycles. A fixed number of operations will be performed by `Ruby6502.exec` so that if not enough ticks are given to complete an operation the processor will not stop mid operation. I.e. if the next two operations require 4 and 2 clock cycles respectively then `Ruby6502.exec(5)` will only perform the first operation, but a subsequent call of `Ruby6502.exec(1)` will perform the second operation (1 tick from the first call and 1 tick from the second).

Maskable and non maskable interrupts can be called with `Ruby6502.interrupt_requset` (program counter set to the two bytes at `0xfffe`) and `Ruby6502.non_maskable_interrupt_request` (program counter set to the two bytes at `0xfffa`).

## Instruction hooks

`ruby6502` provides the ability to run arbitrary ruby code after each 6502 instruction:

```ruby
Ruby6502.load([0x00, 0x80], location: 0xfffc)

program = [
  0xea,               # NOP
  0xea,               # NOP
  0xea,               # NOP
]

Ruby6502.load(program, location: 0x8000)

instruction_hook_count = 0

Ruby6502.register_instruction_hook do
  instruction_hook_count += 1
end

Ruby6502.reset
Ruby6502.step_times(3)

instruction_hook_count # => 3
```

Note that registering instruction hooks will significantly impact the performance of the fake 6502. You can clear all registered instruction hooks with `Ruby6502.clear_instruction_hooks`.

Because instruction hooks impact performance so significantly, common instruction hooks should be written in the C extension. Currently `ruby6502` provides the ability to configure an address at which a random byte will be generated after each instruction. To use:

```ruby
Ruby6502.configure_rng(0x6000) # 0x6000 will have a new random byte after each instruction
```

## Read and write hooks

`ruby6502` provides the ability to run arbitrary ruby code after a read or write to a given address. This can be useful if you want to emulate clearning an interrupt request from a peripheral installed at that address. To use:

```ruby
Ruby6502.load([0x00, 0x80], location: 0xfffc)

program = [
  0xad, 0x00, 0x60,   # LDA $6000
  0x8d, 0x01, 0x60,   # STA $6001
  0xad, 0x02, 0x60,   # LDA $6002
  0x8d, 0x02, 0x60,   # STA $6002
]

Ruby6502.load(program, location: 0x8000)

read_or_write_tracker = nil

Ruby6502.register_read_write_hook(0x6000, :read) do |read_or_write|
  read_or_write_tracker = read_or_write
end

Ruby6502.register_read_write_hook(0x6001, :write) do |read_or_write|
  read_or_write_tracker = read_or_write
end

Ruby6502.register_read_write_hook(0x6002, :read_write) do |read_or_write|
  read_or_write_tracker = read_or_write
end

Ruby6502.reset
read_or_write_tracker # => nil

Ruby6502.step
read_or_write_tracker # => :read

Ruby6502.step
read_or_write_tracker # => :write

Ruby6502.step
read_or_write_tracker # => :read

Ruby6502.step
read_or_write_tracker # => :write
```

Again, read/write hooks will impact performance of the 6502 so once they are no longer needed you should remove them with `Ruby6502.deregister_read_write_hook(location, read_or_write)` where `read_or_write = :read` will clear read hooks for that address, `read_or_write = :write` will clear write hooks and `read_or_write = :read_write` will clear both.
