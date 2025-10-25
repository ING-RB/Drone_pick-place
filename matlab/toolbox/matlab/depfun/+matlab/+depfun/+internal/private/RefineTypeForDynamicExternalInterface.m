function type = RefineTypeForDynamicExternalInterface(sym, type)
    import matlab.depfun.internal.MatlabType
    if startsWith(sym, {'NET.', 'System.'})
        type = MatlabType.DotNetAPI;
    elseif startsWith(sym, 'py.')
        type = MatlabType.PythonAPI;
    elseif startsWith(sym, 'clib.')
        type = MatlabType.CppAPI;
    end
end