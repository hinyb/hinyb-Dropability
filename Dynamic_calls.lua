Dynamic_calls = {}
Dynamic_calls.oP_Step_1 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_1"))
Dynamic_calls.oP_Step_2 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_2"))
return Dynamic_calls
