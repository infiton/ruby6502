#include <stdint.h>
#include <ruby.h>
#include "fake6502.h"

static VALUE mRuby6502;

static VALUE program_counter(VALUE self)
{
  return INT2NUM(getPC());
}

static VALUE stack_pointer(VALUE self)
{
  return INT2NUM(getSP());
}

static VALUE a_register(VALUE self)
{
  return INT2NUM(getA());
}

static VALUE x_register(VALUE self)
{
  return INT2NUM(getX());
}

static VALUE y_register(VALUE self)
{
  return INT2NUM(getY());
}

static VALUE status_flags(VALUE self)
{
  return INT2NUM(getStatus());
}

static VALUE instruction_count(VALUE self)
{
  return INT2NUM(getInstructions());
}

static VALUE reset(VALUE self)
{
  reset6502();
  return Qtrue;
}

static VALUE step(VALUE self)
{
  step6502();
  return instruction_count(self);
}

static VALUE exec(VALUE self, VALUE tickCount)
{
  exec6502((uint32_t) NUM2INT(tickCount));
  return instruction_count(self);
}

uint8_t read6502(uint16_t address)
{
  VALUE memArray = rb_const_get(mRuby6502, rb_intern("MEMORY"));
  VALUE memValue = rb_ary_entry(memArray, address);

  return (uint8_t) NUM2CHR(memValue);
}

void write6502(uint16_t address, uint8_t value)
{
  VALUE memArray = rb_const_get(mRuby6502, rb_intern("MEMORY"));
  VALUE rbValue = INT2NUM(value);

  rb_ary_store(memArray, address, rbValue);
}

void Init_ruby6502()
{
  mRuby6502 = rb_define_module("Ruby6502");
  rb_define_singleton_method(mRuby6502, "_program_counter", program_counter, 0);
  rb_define_singleton_method(mRuby6502, "_stack_pointer", stack_pointer, 0);
  rb_define_singleton_method(mRuby6502, "_a_register", a_register, 0);
  rb_define_singleton_method(mRuby6502, "_x_register", x_register, 0);
  rb_define_singleton_method(mRuby6502, "_y_register", y_register, 0);
  rb_define_singleton_method(mRuby6502, "_status_flags", status_flags, 0);
  rb_define_singleton_method(mRuby6502, "instruction_count", instruction_count, 0);
  rb_define_singleton_method(mRuby6502, "reset", reset, 0);
  rb_define_singleton_method(mRuby6502, "step", step, 0);
  rb_define_singleton_method(mRuby6502, "exec", exec, 1);
}
