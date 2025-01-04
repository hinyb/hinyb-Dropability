Dynamic = {}
Dynamic.oP_Step_1 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_1"))
Dynamic.oP_Step_2 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oP_Step_2"))
Dynamic.oPDrone_Step_2 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oPDrone_Step_2"))
Dynamic.oLizard_Create_0 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oLizard_Create_0"))
Dynamic.oUmbraA_Create_0 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oUmbraA_Create_0"))
Dynamic.oDrifterCube_Create_0 = memory.dynamic_call("int64_t", {"CInstance*", "CInstance*"},
    gm.get_object_function_address("gml_Object_oDrifterCube_Create_0"))
Dynamic.instance_destroy_deep_ptr = memory.scan_pattern("40 57 48 83 EC 70 41 8B C0")
return Dynamic
