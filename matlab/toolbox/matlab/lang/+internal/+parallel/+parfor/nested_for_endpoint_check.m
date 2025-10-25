function nested_for_endpoint_check(varname, varargin)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2007-2019 The MathWorks, Inc.
for i=1:numel(varargin)
    endpoint = varargin{i};
    if ~isscalar(endpoint) || ~isnumeric(endpoint) || ~isreal(endpoint) || ...
       ~isfinite(endpoint) || endpoint ~= round(endpoint) || (endpoint < 1)

       error(message('MATLAB:parfor:InvalidNestedForLoopRangeEndpoint', ...
                varname,...
                doclink( '/toolbox/parallel-computing/distcomp_ug.map', ...
                'ERR_PARFOR_FOR_RANGE', ...
                'parfor-Loops in MATLAB, "Nested for-Loops with Sliced Variables"')))
    end
end
end
