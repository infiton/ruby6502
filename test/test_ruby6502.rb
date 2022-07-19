# frozen_string_literal: true

require "minitest/autorun"
require "ruby6502"

class Ruby6502Test < Minitest::Test
  def test_memory_size
    assert_equal(0x10000, Ruby6502.memory_size)
  end

  def test_load_and_read_byte
    Ruby6502.load([0xab, 0xba], location: 0x1aa1)

    assert_equal(
      [0xab, 0xba],
      Ruby6502.read(location: 0x1aa1, bytes: 2)
    )
  end

  def test_program_counter
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.reset

    assert_equal(0x8000, Ruby6502.program_counter)
  end

  def test_stack_pointer
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xa2, 0xab,       # LDX #$ab
      0x9a,             # TXS
    ], location: 0x8000)
    Ruby6502.reset

    Ruby6502.step_times(2)

    assert_equal(0xab, Ruby6502.stack_pointer)
  end

  def test_a_register
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xa9, 0xcc,       # LDA #$cc
    ], location: 0x8000)
    Ruby6502.reset

    Ruby6502.step

    assert_equal(0xcc, Ruby6502.a_register)
  end

  def test_x_register
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xa2, 0xdd,       # LDX #$dd
    ], location: 0x8000)
    Ruby6502.reset

    Ruby6502.step

    assert_equal(0xdd, Ruby6502.x_register)
  end

  def test_y_register
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xa0, 0xee,       # LDY #$ee
    ], location: 0x8000)
    Ruby6502.reset

    Ruby6502.step

    assert_equal(0xee, Ruby6502.y_register)
  end

  def test_status_flags
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0x38,             # SEC
      0x78,             # SEI
      0xf8,             # SED
    ], location: 0x8000)
    Ruby6502.reset

    Ruby6502.step_times(3)

    assert_equal(0b00001101, 0b00001101 & Ruby6502.status_flags)
  end

  def test_instruction_count
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xea,             # NOP
    ] * 10, location: 0x8000)
    Ruby6502.reset

    assert_equal(0, Ruby6502.instruction_count)
    Ruby6502.step_times(10)
    assert_equal(10, Ruby6502.instruction_count)
  end

  def test_tick_count
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xea,             # NOP
    ] * 10, location: 0x8000)
    Ruby6502.reset

    assert_equal(0, Ruby6502.tick_count)
    Ruby6502.exec(20)
    assert_equal(20, Ruby6502.tick_count)
  end

  def test_reset
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([
      0xea,             # NOP
    ] * 10, location: 0x8000)
    Ruby6502.reset

    Ruby6502.exec(20)
    Ruby6502.reset

    assert_equal(0x8000, Ruby6502.program_counter)
    assert_equal(0, Ruby6502.instruction_count)
    assert_equal(0, Ruby6502.tick_count)
  end

  def test_interrupt_request
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([0x00, 0xff], location: 0xfffe)

    Ruby6502.load([
      0xea,             # NOP
    ], location: 0x8000)

    Ruby6502.reset
    assert_equal(0x8000, Ruby6502.program_counter)
    Ruby6502.step

    Ruby6502.interrupt_request
    assert_equal(0xff00, Ruby6502.program_counter)
  end

  def test_interrupt_request_is_maskable
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([0x00, 0xff], location: 0xfffe)

    Ruby6502.load([
      0x78,             # SEI
    ], location: 0x8000)

    Ruby6502.reset
    assert_equal(0x8000, Ruby6502.program_counter)
    Ruby6502.step

    Ruby6502.interrupt_request
    assert_equal(0x8001, Ruby6502.program_counter)
  end

  def test_non_maskable_interrupt
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([0x00, 0xff], location: 0xfffa)

    Ruby6502.load([
      0xea,             # NOP
    ], location: 0x8000)

    Ruby6502.reset
    assert_equal(0x8000, Ruby6502.program_counter)
    Ruby6502.step

    Ruby6502.non_maskable_interrupt
    assert_equal(0xff00, Ruby6502.program_counter)
  end

  def test_non_maskable_interrupt_is_not_maskable
    Ruby6502.load([0x00, 0x80], location: 0xfffc)
    Ruby6502.load([0x00, 0xff], location: 0xfffa)

    Ruby6502.load([
      0x78,             # SEI
    ], location: 0x8000)

    Ruby6502.reset
    assert_equal(0x8000, Ruby6502.program_counter)
    Ruby6502.step

    Ruby6502.non_maskable_interrupt
    assert_equal(0xff00, Ruby6502.program_counter)
  end

  def test_register_instruction_hook
    Ruby6502.load([0x00, 0x80], location: 0xfffc)

    Ruby6502.load([
      0xea,             # NOP
    ], location: 0x8000)

    @hook_counter = 0

    Ruby6502.register_instruction_hook do
      @hook_counter += 1
    end

    Ruby6502.reset

    assert_equal(0, @hook_counter)
    Ruby6502.step
    assert_equal(1, @hook_counter)

    Ruby6502.clear_instruction_hooks
    Ruby6502.reset

    Ruby6502.step
    assert_equal(1, @hook_counter)
  end

  def test_register_read_hook
    Ruby6502.load([0x00, 0x80], location: 0xfffc)

    Ruby6502.load([
      0xad, 0xfa, 0xfa, # LDA $fafa
      0xae, 0xfa, 0xfa, # LDX $fafa
    ], location: 0x8000)

    @hook_counter = 0

    Ruby6502.register_read_write_hook(0xfafa, :read) do
      @hook_counter += 1
    end

    Ruby6502.reset

    assert_equal(0, @hook_counter)
    Ruby6502.step
    assert_equal(1, @hook_counter)

    Ruby6502.deregister_read_write_hook(0xfafa, :read)
    Ruby6502.step
    assert_equal(1, @hook_counter)
  end

  def test_register_write_hook
    Ruby6502.load([0x00, 0x80], location: 0xfffc)

    Ruby6502.load([
      0x8d, 0xfa, 0xfa, # STA $fafa
      0x8d, 0xfa, 0xfa, # STA $fafa
    ], location: 0x8000)

    @hook_counter = 0

    Ruby6502.register_read_write_hook(0xfafa, :write) do
      @hook_counter += 1
    end

    Ruby6502.reset

    assert_equal(0, @hook_counter)
    Ruby6502.step
    assert_equal(1, @hook_counter)

    Ruby6502.deregister_read_write_hook(0xfafa, :write)
    Ruby6502.step
    assert_equal(1, @hook_counter)
  end

  def test_register_read_write_hook
    Ruby6502.load([0x00, 0x80], location: 0xfffc)

    Ruby6502.load([
      0xad, 0xfa, 0xfa, # LDA $fafa
      0x8d, 0xfa, 0xfa, # STA $fafa
      0xad, 0xfa, 0xfa, # LDA $fafa
    ], location: 0x8000)

    @hook_counter = 0

    Ruby6502.register_read_write_hook(0xfafa, :read_write) do
      @hook_counter += 1
    end

    Ruby6502.reset

    assert_equal(0, @hook_counter)
    Ruby6502.step
    assert_equal(1, @hook_counter)
    Ruby6502.step
    assert_equal(2, @hook_counter)

    Ruby6502.deregister_read_write_hook(0xfafa, :read_write)
    Ruby6502.step
    assert_equal(2, @hook_counter)
  end

  def test_configure_rng
    Ruby6502.load([0x00, 0x80], location: 0xfffc)

    Ruby6502.load([
      0xa9, 0x00,       # LDA #$00
      0x85, 0xfe,       # STA $fe
      0xa5, 0xfe,       # LDA $fe
      0xa5, 0xfe,       # LDA $fe
      0xa5, 0xfe,       # LDA $fe
      0xa5, 0xfe,       # LDA $fe
      0xa5, 0xfe,       # LDA $fe
      0xa5, 0xfe,       # LDA $fe
    ], location: 0x8000)

    Ruby6502.configure_rng(0xfe)

    Ruby6502.reset
    Ruby6502.step_times(2)

    random_numbers = 6.times.map do
      Ruby6502.step
      Ruby6502.a_register
    end

    refute_equal(0, random_numbers.sum)
  end
end
