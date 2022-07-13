# frozen_string_literal: true

require "ruby6502/ruby6502"

module Ruby6502
  MEMORY = [0] * 256 * 256
  HOOKS = []

  def self.load(bytearray, location: 0)
    byte_size = bytearray.size
    if MEMORY.size < location + byte_size
      raise "Loading #{byte_size} bytes to #{format("%04x", location)} would overflow memory"
    end

    bytearray.each do |byte|
      MEMORY[location] = byte
      location += 1
    end
  end

  def self.read(location:, bytes:)
    raise "#{format("%04x", location)} is outside bounds" if location >= MEMORY.size

    MEMORY[location...location + bytes]
  end

  def self.execute_hooks
    HOOKS.each(&:call)
  end

  def self.register_hook(&hook)
    set_hooks unless hooks?
    HOOKS << hook
  end

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
