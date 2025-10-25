function mustBeValidGraphicsObject(input, cls)
% mustBeValidGraphicsObject is for internal use only and may be removed or
% modified at any time

% mustBeValidGraphicsObject(input, class) issues an error if input is not
% an empty double, a valid graphics handle or the specified input class
%
    
%   Copyright 2019-2023 The MathWorks, Inc.

    % is_valid_graphics_property.cpp need to be updated to work with ResolvedName
    % PKG_TODO
    out = is_valid_graphics_property(input, cls); 
    if ~out
        throwAsCaller(MException('MATLAB:type:PropSetClsMismatch','%s',message('MATLAB:type:PropSetClsMismatch',cls).getString));
    end   
end
