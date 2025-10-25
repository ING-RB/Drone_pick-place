function [dt, waslegacy] = convertDatenum(dt)
%

%   Copyright 2021-2024 The MathWorks, Inc.

if isa(dt,'datetime')
    waslegacy = false;
elseif isnumeric(dt) 
    waslegacy = true;
    dt = datetime(dt,"ConvertFrom","datenum");
elseif iscellstr(dt) || (isstring(dt) && ~isscalar(dt))
    waslegacy = true;
    % Convert to vector for consistent datenum behavior, then preserve the
    % original shape.
    dims = size(dt);
    dt = datetime(datenum(dt(:)),"ConvertFrom","datenum"); %#ok<DATNM>
    dt = reshape(dt,dims);
elseif ischar(dt) || isstring(dt)
    waslegacy = true;
    dt = datetime(datenum(dt),"ConvertFrom","datenum"); %#ok<DATNM>
else
    error(message("MATLAB:datetime:convertDatenum:InvalidDate"));
end
