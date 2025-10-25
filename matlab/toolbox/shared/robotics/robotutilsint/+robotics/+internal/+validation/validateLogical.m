function validLogical = validateLogical( inValue, varargin )
%This function is for internal use only. It may be removed in the future.

%validateLogical Validate an input that could be interpreted as logical
%   VALIDLOGICAL = robotics.internal.validation.validateLogical(INVALUE)
%   checks if INVALUE can be interpreted as a valid logical value. The
%   output, VALIDLOGICAL, is always guaranteed to be a scalar logical.

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

    validateattributes(inValue, {'logical', 'numeric'}, ...
                       {'nonempty', 'scalar', 'real'}, varargin{:});

    % Cast output to logical
    validLogical = logical(inValue);

end
