function out = isValidInputForLogical(val, propName)
%isValidInputForLogical Check if the input is a scalar logical value

%   Copyright 2019 The MathWorks, Inc.

    out = false;
    
    if isscalar(val)
        if islogical(val) 
            out = true;
        elseif isnumeric(val) 
            if (isequal(val, 1) || isequal(val, 0))
                out = true;
            end
        end
    end
    
    if isequal(out, false)
        error(message(...
            'MATLAB:settings:config:ValueMustBeScalarLogical', propName));
    end
end
