function endpoint = endpoint_check(varname, endpoint)
% This function is undocumented and reserved for internal use.  It may be
% removed in a future release.

% Copyright 2007-2019 The MathWorks, Inc.

% The endpoint of a parfor range expression must evaluate to a scalar
% integer.

% The new front-end expects a varname and a range expression.

% The isscalar test ensures that all other tests return a scalar logical.
% The functions isfinite and round can produce non-scalar results.
if ~isscalar(endpoint) || ~isnumeric(endpoint) || ~isreal(endpoint) ...
   || ~isfinite(endpoint) || endpoint ~= round(endpoint)
    error(message('MATLAB:parfor:range_endpoint', ...
              varname, ...
              doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));

    % Before R2019b
    % error(message('MATLAB:parfor:range_endpoint', '', doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
end
