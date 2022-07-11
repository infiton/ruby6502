# frozen_string_literal: true

require "ruby6502/ruby6502"

module Ruby6502
  MEMORY = [0] * 256 * 256

  def self.program_counter
    format("%04x", _program_counter)
  end

  def self.stack_pointer
    format("%02x", _stack_pointer)
  end

  def self.a_register
    format("%02x", _a_register)
  end

  def self.x_register
    format("%02x", _x_register)
  end

  def self.y_register
    format("%02x", _y_register)
  end

  def self.status_flags
    format("%08b", _status_flags)
  end
end
