# frozen_string_literal: true

require "ruby6502/ruby6502"

module Ruby6502
  INSTRUCTION_HOOKS = []
  READ_WRITE_HOOKS = {}

  def self.load(bytearray, location: 0)
    byte_size = bytearray.size
    location = location.to_i

    if location < 0
      raise "Cannot load to a negative memory location"
    end

    if memory_size < location + byte_size
      raise "Loading #{byte_size} bytes to #{format("%04x", location)} would overflow memory"
    end

    bytearray.each do |byte|
      byte_to_load = byte.to_i & 0xff
      load_byte(location, byte_to_load)
      location += 1
    end
  end

  def self.read(location:, bytes:)
    location = location.to_i
    bytes = bytes.to_i

    unless location >=0 && location < memory_size
      raise "#{location} is outside memory bounds"
    end

    unless bytes >= 0
      raise "Must read a positive number of bytes"
    end

    raise "#{format("%04x", location + bytes)} is outside bounds" if location + bytes > memory_size

    bytes.times.map do |byte|
      read_byte(location + byte)
    end
  end

  def self.execute_instruction_hooks
    INSTRUCTION_HOOKS.each(&:call)
  end

  def self.register_instruction_hook(&hook)
    set_instruction_hooks unless instruction_hooks?
    INSTRUCTION_HOOKS << hook
  end

  def self.execute_read_write_hook(location, read_or_write)
    READ_WRITE_HOOKS[[location, read_or_write]]&.call(read_or_write)
  end

  def self.register_read_write_hook(location, read_or_write, &hook)
    read_or_write = read_or_write.to_sym
    unless [:read, :write, :read_write].include?(read_or_write)
      raise "#{read_or_write} must be one of :read, :write, :read_write"
    end

    set_read_write_hooks unless read_write_hooks?

    if read_or_write == :read_write
      READ_WRITE_HOOKS[[location, :read]] = hook
      READ_WRITE_HOOKS[[location, :write]] = hook
    else
      READ_WRITE_HOOKS[[location, read_or_write]] = hook
    end
  end

  def self.deregister_read_write_hook(location, read_or_write)
    if read_or_write == :read_write
      READ_WRITE_HOOKS.delete([location, :read])
      READ_WRITE_HOOKS.delete([location, :write])
    else
      READ_WRITE_HOOKS.delete([location, read_or_write])
    end

    unset_read_write_hooks if READ_WRITE_HOOKS.empty?
  end
end
