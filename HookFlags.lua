-- now only event use this.
HookFlags = {
    fNone = (0 << 0),
    fDelete = (1 << 0),
    fSkipOriginal = (1 << 1),
    fSkipQueue = (1 << 2)
}
return HookFlags