#include <stdint.h>
#include <ruby.h>
#include "fake6502.h"

static VALUE mRuby6502;
uint8_t has_instruction_hooks = 0;
uint8_t has_read_write_hooks = 0;

#define MEMSIZE 0x10000
uint8_t MEMORY[MEMSIZE] = {0};

static VALUE program_counter(VALUE self)
{
  return UINT2NUM(getPC());
}

static VALUE stack_pointer(VALUE self)
{
  return UINT2NUM(getSP());
}

static VALUE a_register(VALUE self)
{
  return UINT2NUM(getA());
}

static VALUE x_register(VALUE self)
{
  return UINT2NUM(getX());
}

static VALUE y_register(VALUE self)
{
  return UINT2NUM(getY());
}

static VALUE status_flags(VALUE self)
{
  return UINT2NUM(getStatus());
}

static VALUE instruction_count(VALUE self)
{
  return ULONG2NUM(getInstructions());
}

static VALUE tick_count(VALUE self)
{
  return ULL2NUM(getTicks());
}

static VALUE reset(VALUE self)
{
  reset6502();
  return Qtrue;
}

static VALUE interrupt_request(VALUE self)
{
  irq6502();
  return Qtrue;
}

static VALUE non_maskable_interrupt(VALUE self)
{
  nmi6502();
  return Qtrue;
}

static VALUE step(VALUE self)
{
  step6502();
  return instruction_count(self);
}

static VALUE step_times(VALUE self, VALUE stepCount)
{
  int steps = NUM2INT(stepCount);
  for(int i = 0; i < steps; ++i) {
    step6502();
  }

  return instruction_count(self);
}

static VALUE exec(VALUE self, VALUE tickCount)
{
  exec6502((uint32_t) NUM2ULONG(tickCount));
  return instruction_count(self);
}

static VALUE memory_size(VALUE self)
{
  return UINT2NUM(MEMSIZE);
}

uint8_t read_address(uint16_t address)
{
  if ( address >= 0 && address < MEMSIZE ) {
    return MEMORY[address];
  } else return 0;
}

uint8_t read6502(uint16_t address)
{

  if ( has_read_write_hooks ) {
    rb_funcall(mRuby6502, rb_intern("execute_read_write_hook"), 2, UINT2NUM(address), ID2SYM(rb_intern("read")));
  }

  return read_address(address);
}

static VALUE read_byte(VALUE self, VALUE location)
{
  uint16_t address;

  address = (uint16_t) NUM2UINT(location);

  return UINT2NUM(read_address(address));
}

void write_address(uint16_t address, uint8_t value)
{
  if ( address >= 0 && address < MEMSIZE ) {
    MEMORY[address] = value;
  }
}

void write6502(uint16_t address, uint8_t value)
{
  if ( has_read_write_hooks ) {
    rb_funcall(mRuby6502, rb_intern("execute_read_write_hook"), 2, INT2NUM(address), ID2SYM(rb_intern("write")));
  }

  write_address(address, value);
}

static VALUE load_byte(VALUE self, VALUE location, VALUE r_value)
{
  uint16_t address;
  uint8_t value;

  address = (uint16_t) NUM2UINT(location);
  value = (uint8_t) NUM2UINT(r_value);

  write_address(address, value);

  return location;
}

static VALUE set_instruction_hooks(VALUE self)
{
  has_instruction_hooks = 1;
  return Qtrue;
}

static VALUE unset_instruction_hooks(VALUE self)
{
  has_instruction_hooks = 0;
  return Qtrue;
}

static VALUE get_has_instruction_hooks(VALUE self)
{
  if (has_instruction_hooks) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

static VALUE set_read_write_hooks(VALUE self)
{
  has_read_write_hooks = 1;
  return Qtrue;
}

static VALUE unset_read_write_hooks(VALUE self)
{
  has_read_write_hooks = 0;
  return Qtrue;
}

static VALUE get_has_read_write_hooks(VALUE self)
{
  if (has_read_write_hooks) {
    return Qtrue;
  } else {
    return Qfalse;
  }
}

void execute_instruction_hooks() {
  if (has_instruction_hooks) {
    rb_funcall(mRuby6502, rb_intern("execute_instruction_hooks"), 0);
  }
}

void Init_ruby6502()
{
  mRuby6502 = rb_define_module("Ruby6502");
  rb_define_singleton_method(mRuby6502, "memory_size", memory_size, 0);
  rb_define_singleton_method(mRuby6502, "read_byte", read_byte, 1);
  rb_define_singleton_method(mRuby6502, "load_byte", load_byte, 2);

  rb_define_singleton_method(mRuby6502, "program_counter", program_counter, 0);
  rb_define_singleton_method(mRuby6502, "stack_pointer", stack_pointer, 0);
  rb_define_singleton_method(mRuby6502, "a_register", a_register, 0);
  rb_define_singleton_method(mRuby6502, "x_register", x_register, 0);
  rb_define_singleton_method(mRuby6502, "y_register", y_register, 0);
  rb_define_singleton_method(mRuby6502, "status_flags", status_flags, 0);
  rb_define_singleton_method(mRuby6502, "instruction_count", instruction_count, 0);
  rb_define_singleton_method(mRuby6502, "tick_count", tick_count, 0);

  rb_define_singleton_method(mRuby6502, "set_instruction_hooks", set_instruction_hooks, 0);
  rb_define_singleton_method(mRuby6502, "unset_instruction_hooks", unset_instruction_hooks, 0);
  rb_define_singleton_method(mRuby6502, "instruction_hooks?", get_has_instruction_hooks, 0);

  rb_define_singleton_method(mRuby6502, "set_read_write_hooks", set_read_write_hooks, 0);
  rb_define_singleton_method(mRuby6502, "unset_read_write_hooks", unset_read_write_hooks, 0);
  rb_define_singleton_method(mRuby6502, "read_write_hooks?", get_has_read_write_hooks, 0);

  rb_define_singleton_method(mRuby6502, "reset", reset, 0);
  rb_define_singleton_method(mRuby6502, "interrupt_request", interrupt_request, 0);
  rb_define_singleton_method(mRuby6502, "non_maskable_interrupt", non_maskable_interrupt, 0);
  rb_define_singleton_method(mRuby6502, "step", step, 0);
  rb_define_singleton_method(mRuby6502, "step_times", step_times, 1);
  rb_define_singleton_method(mRuby6502, "exec", exec, 1);

  hookexternal(execute_instruction_hooks);
}
