function validateParameter(parameter)
%

%   Copyright 2018 The MathWorks, Inc.

classname = "matlab.unittest.parameters.Parameter";
validateattributes(parameter,classname,{});
parameter = parameter(:).';
classes = arrayfun(@class, parameter(:).', 'UniformOutput', false);
if any(classname ~= classes)
    error(message('MATLAB:unittest:Parameter:MustBeParameter'))
end
end
