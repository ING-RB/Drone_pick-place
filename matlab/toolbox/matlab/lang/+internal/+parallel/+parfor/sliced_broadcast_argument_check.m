function sliced_broadcast_argument_check(varname, argname, arg)
%

% Copyright 2017-2019 The MathWorks, Inc.
%
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% When indexing sliced variables with broadcast variable arguments,
% arguments must be positive integers or logicals.

if (~isnumeric(arg) || (~isreal(arg) && any(imag(arg),'all')) || any(~isfinite(arg),'all') || ...
        any(arg <= 0, 'all') || any(arg ~= round(arg), 'all')) && ~islogical(arg)
    
    error(message('MATLAB:parfor:InvalidBroadcastSlicedVariableArgument',...
        varname,...
        argname,...
        doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
        'SLICED_VARIABLES',...
        'parfor-Loops in MATLAB, "Sliced Variables"')));
end

