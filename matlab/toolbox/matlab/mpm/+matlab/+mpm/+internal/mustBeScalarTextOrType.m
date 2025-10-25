function mustBeScalarTextOrType(value, type)
    if isa(value, type ) && isscalar(value)
        return
    end
    try
        mustBeTextScalar(value)
    catch ex
            throwAsCaller(MException("mpm:arguments:InvalidArgumentType",...
                                 message("mpm:arguments:InvalidArgumentTypeOneOf", ...
                                         "Value", ...
                                         message("mpm:arguments:InvalidArgumentTwoTypes", "scalar text", type).string()).string()));
    end
end