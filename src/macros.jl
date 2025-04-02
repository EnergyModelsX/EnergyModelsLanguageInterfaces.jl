using Libdl

"""
    @dlsym(lib, func)

This macro uses `dlsym` to load a function from a shared library specified by `lib` and `func`.
It caches the result in a `Ref` to avoid repeated lookups. If the symbol is already loaded,
it returns the cached pointer. Otherwise, it loads the symbol, caches it, and then returns
the pointer.
"""
macro dlsym(lib, func)
    z = Ref{Ptr{Cvoid}}(C_NULL)
    quote
        let zlocal = $z[]
            if zlocal == C_NULL
                zlocal = dlsym($(esc(lib))::Ptr{Cvoid}, $(esc(func)))::Ptr{Cvoid}
                $z[] = zlocal
            end
            zlocal
        end
    end
end
