function useParallel = validateUseParallel(useParallel)
%validateUseParallel    Validate that UseParallel has a scalar logical
%   value

%   Copyright 2023 The MathWorks, Inc.
    validateattributes(useParallel, {'logical'}, {'scalar'}, 'write', 'UseParallel');
    useParallel = logical(useParallel);
end