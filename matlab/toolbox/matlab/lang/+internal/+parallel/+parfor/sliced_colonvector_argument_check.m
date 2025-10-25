function sliced_colonvector_argument_check(varname, argname, arg)
%

% Copyright 2024 The MathWorks, Inc.
%
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% When indexing sliced variables with colonvector arguments, A:[S:]D, each of
% A,S,D must be scalar numeric real finite integer-valued.

try
    mustBeNonempty(arg);
    mustBeScalarOrEmpty(arg);
    % mustBeInteger permits logical, so rule that out with mustBeNumeric.
    mustBeNumeric(arg);
    mustBeInteger(arg);
catch
    error(message('MATLAB:parfor:InvalidSlicedColonVector', ...
                  varname, argname, ...
                  doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
                           'SLICED_VARIABLES',...
                           'parfor-Loops in MATLAB, "Sliced Variables"')));
end
end
