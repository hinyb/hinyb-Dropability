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
Dynamic.YYGML_NewWithIterator = memory.scan_pattern("48 89 5C 24 ? 48 89 6C 24 ? 48 89 74 24 ? 57 41 54 41 55 41 56 41 57 48 83 EC 20 48 8B 02")
Dynamic.event_perform_internal = memory.scan_pattern("48 89 5C 24 ? 55 41 54 41 57 48 83 EC 20 83 79")

return Dynamic
