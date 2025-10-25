function validateBuildFlags(compilerLinkerFlags)
% Validate build flags

%   Copyright 2024 The MathWorks, Inc.

validateattributes(compilerLinkerFlags, {'string', 'char','cell'},{'nonempty', 'vector', 'row'});

if(iscell(compilerLinkerFlags) && ~iscellstr(compilerLinkerFlags))
    error(message('MATLAB:CPP:InvalidTypeCompilerLinkerFlags'));
end

end

