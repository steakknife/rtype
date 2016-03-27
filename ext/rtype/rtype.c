#include "rtype.h"

VALUE rb_mRtype, rb_mRtypeBehavior, rb_cRtypeBehaviorBase, rb_eRtypeArgumentTypeError, rb_eRtypeTypeSignatureError, rb_eRtypeReturnTypeError;

VALUE
rb_rtype_valid(VALUE self, VALUE expected, VALUE value) {
	switch(TYPE(expected)) {
		case T_MODULE:
		case T_CLASS:
			return rb_obj_is_kind_of(value, expected) ? Qtrue : Qfalse;
		case T_SYMBOL:
			return rb_respond_to(value, rb_to_id(expected)) ? Qtrue : Qfalse;
		case T_REGEXP:
			return rb_reg_match( expected, rb_funcall(value, rb_intern("to_s"), 0) ) != Qnil ? Qtrue : Qfalse;
		case T_ARRAY:
			if( !RB_TYPE_P(value, T_ARRAY) ) {
				return Qfalse;
			}
			else if( RARRAY_LEN(expected) != RARRAY_LEN(value) ) {
				return Qfalse;
			}
			else {
				// 'for' loop initial declarations are only allowed in c99 mode
				long i;
				for(i = 0; i < RARRAY_LEN(expected); i++) {
					VALUE e = rb_ary_entry(expected, i);
					VALUE v = rb_ary_entry(value, i);
					VALUE valid = rb_rtype_valid(self, e, v);
					if(valid == Qfalse) {
						return Qfalse;
					}
				}
				return Qtrue;
			}
		case T_TRUE:
			return RTEST(value) ? Qtrue : Qfalse;
		case T_FALSE:
			return !RTEST(value) ? Qtrue : Qfalse;
		default:
			if(rb_obj_is_kind_of(expected, rb_cRange)) {
				return rb_funcall(expected, rb_intern("include?"), 1, value);
			}
			else if(rb_obj_is_kind_of(expected, rb_cProc)) {
				return RTEST(rb_funcall(expected, rb_intern("call"), 1, value)) ? Qtrue : Qfalse;
			}
			else if( RTEST(rb_obj_is_kind_of(expected, rb_cRtypeBehaviorBase)) ) {
				return rb_funcall(expected, rb_intern("valid?"), 1, value);
			}
			else {
				VALUE str = rb_any_to_s(expected);
				rb_raise(rb_eRtypeTypeSignatureError, "Invalid type signature: Unknown type behavior %s", StringValueCStr(str));
				return Qfalse;
			}
	}
}

VALUE
rb_rtype_assert_arguments_type(VALUE self, VALUE expected_args, VALUE args) {
	// 'for' loop initial declarations are only allowed in c99 mode
	long i;
	for(i = 0; i < RARRAY_LEN(args); i++) {
		VALUE e = rb_ary_entry(expected_args, i);
		VALUE v = rb_ary_entry(args, i);
		if(e != Qnil) {
			if( !RTEST(rb_rtype_valid(self, e, v)) ) {
				VALUE msg = rb_funcall(rb_mRtype, rb_intern("arg_type_error_message"), 3, LONG2FIX(i), e, v);
				rb_raise(rb_eRtypeArgumentTypeError, "%s", StringValueCStr(msg));
			}
		}
	}
	return Qnil;
}

static int
kwargs_do_each(VALUE key, VALUE val, VALUE in) {
	VALUE expected = rb_hash_aref(in, key);
	if(expected != Qnil) {
		if( !RTEST(rb_rtype_valid((VALUE) NULL, expected, val)) ) {
			VALUE msg = rb_funcall(rb_mRtype, rb_intern("kwarg_type_error_message"), 3, key, expected, val);
			rb_raise(rb_eRtypeArgumentTypeError, "%s", StringValueCStr(msg));
		}
	}
	return ST_CONTINUE;
}

VALUE
rb_rtype_assert_arguments_type_with_keywords(VALUE self, VALUE expected_args, VALUE args, VALUE expected_kwargs, VALUE kwargs) {
	rb_rtype_assert_arguments_type(self, expected_args, args);
	rb_hash_foreach(kwargs, kwargs_do_each, expected_kwargs);
	return Qnil;
}

VALUE
rb_rtype_assert_return_type(VALUE self, VALUE expected, VALUE result) {
	if(expected == Qnil) {
		if(result != Qnil) {
			VALUE msg = rb_funcall(rb_mRtype, rb_intern("type_error_message"), 2, expected, result);
			rb_raise(rb_eRtypeReturnTypeError, "for return:\n %s", StringValueCStr(msg));
		}
	}
	else {
		if( !RTEST(rb_rtype_valid(self, expected, result)) ) {
			VALUE msg = rb_funcall(rb_mRtype, rb_intern("type_error_message"), 2, expected, result);
			rb_raise(rb_eRtypeReturnTypeError, "for return:\n %s", StringValueCStr(msg));
		}
	}
	return Qnil;
}

void Init_rtype_native(void) {
	rb_mRtype = rb_define_module("Rtype");
	rb_mRtypeBehavior = rb_define_module_under(rb_mRtype, "Behavior");
	rb_cRtypeBehaviorBase = rb_define_class_under(rb_mRtypeBehavior, "Base", rb_cObject);
	rb_eRtypeArgumentTypeError = rb_define_class_under(rb_mRtype, "ArgumentTypeError", rb_eArgError);
	rb_eRtypeTypeSignatureError = rb_define_class_under(rb_mRtype, "TypeSignatureError", rb_eArgError);
	rb_eRtypeReturnTypeError = rb_define_class_under(rb_mRtype, "ReturnTypeError", rb_eStandardError);

	rb_define_singleton_method(rb_mRtype, "valid?", rb_rtype_valid, 2);
	rb_define_singleton_method(rb_mRtype, "assert_arguments_type", rb_rtype_assert_arguments_type, 2);
	rb_define_singleton_method(rb_mRtype, "assert_arguments_type_with_keywords", rb_rtype_assert_arguments_type_with_keywords, 4);
	rb_define_singleton_method(rb_mRtype, "assert_return_type", rb_rtype_assert_return_type, 2);
}