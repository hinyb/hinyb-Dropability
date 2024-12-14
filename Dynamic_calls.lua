Dynamic_calls = {}
Dynamic_calls.oP_Step_1 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_1"))
Dynamic_calls.oP_Step_2 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_2"))
Dynamic_calls.oLizard_Create_0 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
gm.get_object_function_address("gml_Object_oLizard_Create_0"))
Dynamic_calls.oUmbraA_Create_0 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
gm.get_object_function_address("gml_Object_oUmbraA_Create_0"))



return Dynamic_calls
