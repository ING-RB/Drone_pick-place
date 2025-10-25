function validate2DWindow(window)
%validate2DWindow Validate window for 2D functions
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023-2024 The MathWorks, Inc.

if ~(isnumeric(window) || isduration(window) || iscell(window))
    error(message("MATLAB:gridded2DData:InvalidWindowType"));
end

if isnumeric(window) || isduration(window)
    if ~isscalar(window)
        error(message("MATLAB:gridded2DData:InvalidNumericDurationWindowSize"));
    end
    validateScalarWindow(window);
elseif iscell(window)
    if numel(window) ~= 2 || ~((isscalar(window{1}) || numel(window{1}) == 2) && ...
            (isscalar(window{2}) || numel(window{2}) == 2))
        error(message("MATLAB:gridded2DData:InvalidWindowCellSize"));
    elseif ~(isnumeric(window{1}) || isduration(window{1})) || ~(isnumeric(window{2}) || isduration(window{2}))
        error(message("MATLAB:gridded2DData:InvalidWindowCellType"));
    end
    if isscalar(window{1})
        validateScalarWindow(window{1});
    else
        validateVectorWindow(window{1});
    end

    if isscalar(window{2})
        validateScalarWindow(window{2});
    else
        validateVectorWindow(window{2});
    end
end
end

function validateScalarWindow(window)
if ~(window > 0) || ~isreal(window) || ~isfinite(window)
    error(message("MATLAB:gridded2DData:InvalidWindowValueScalar"));
end
end

function validateVectorWindow(window)
if ~(all(window >= 0)) || ~isreal(window) || ~allfinite(window)
    error(message("MATLAB:gridded2DData:InvalidWindowValueVector"));
end
end