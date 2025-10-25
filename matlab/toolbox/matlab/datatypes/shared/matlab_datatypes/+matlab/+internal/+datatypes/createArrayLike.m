function obj = createArrayLike(template, sz, fillval)
% CREATEARRAYLIKE Create an array of a specified size and class.
% 
% This function is for internal use only and will change in a future release.
% Do not use this function.

% Copyright 2024 The MathWorks, Inc.

try
    if ~isscalar(fillval) % must be scalar
        error(message("MATLAB:createArray:invalidFillValueForClass",class(template)));
    end
    
    try
        % Combine the template and the fill value by first converting the
        % template into a 1x0 empty row vector and then growing it by
        % assigning the fill value to the first element. The first step is
        % necessary to ensure the assignment works for array of any size
        % (including N-dimensional empties).
        % Fill value can be a different type from the template, as long as
        % it is a supported by template's paren assignment method.
        %
        % This function assumes that template supports linear indexing.

        template = template(1:0);
        template(1) = fillval;
    catch ME
        ME = addCause(MException(message('MATLAB:createArray:genericError')), ME);
        throw(ME);
    end

    % At this point template is guaranteed to be a non-empty array with the
    % first element being the correct value. So call createArray with the
    % first element as the FillValue to do the remainder of the work.
    obj = createArray(sz, FillValue=template(1));
catch ME
    throwAsCaller(ME);
end