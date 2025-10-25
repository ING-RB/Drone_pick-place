function invarr = invalidHandle(className, dims)
    arguments
        className {mustBeTextScalar, mustBeNonzeroLengthText}
    end
    arguments(Repeating)
        dims double {mustBeNonnegative, mustBeInteger}
    end
    metacls = matlab.metadata.Class.fromName(className);
    if isempty(metacls)
        msg = 'MATLAB:class:ClassNotFoundOnPath';
        error(msg, message(msg, className).getString());
    end
    if metacls.Abstract
        msg = 'MATLAB:class:AbstractCannotInstantiate';
        error(msg, message(msg, className).getString());
    end

    if (nargin == 1 || prod([dims{:}]) == 1)
        invarr = matlab.lang.internal.invalidHandle(metacls);
    else
        invarr = createArray(dims{:}, "FillValue", matlab.lang.internal.invalidHandle(metacls));
    end
end
