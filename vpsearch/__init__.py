# Load Parasail DLL. This must happen before any vpsearch-specific modules are
# imported.

def _load_parasail():
    import ctypes
    import parasail
    ctypes.CDLL(parasail.get_library(), mode=ctypes.RTLD_GLOBAL)


_load_parasail()
del _load_parasail
