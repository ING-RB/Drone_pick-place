function toArrowStruct = matlab2arrow(array)
%MATLAB.IO.ARROW.INTERNAL.MATLAB2ARROW
%   Deconstructs a native MATLAB array into a primitive array or a struct array
%   which can be used by the MEX layer.
%   Also does UTF-16 to UTF-8 conversion for strings types, and bit-packing for
%   logical types.

%   Copyright 2018-2022 The MathWorks, Inc.

    import matlab.io.arrow.internal.matlab2arrow.buildStructStruct
    import matlab.io.arrow.internal.matlab2arrow.buildArrayStruct
    
    if istabular(array)
        toArrowStruct = buildStructStruct(array);
    else
        toArrowStruct = buildArrayStruct(array);
    end
end

