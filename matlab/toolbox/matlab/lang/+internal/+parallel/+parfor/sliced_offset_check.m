function sliced_offset_check(varname, k)
%

% Copyright 2017-2019 The MathWorks, Inc.
%
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% A sliced variable offset value must be a constant scalar integer.
if (~isscalar(k) || ~isnumeric(k) || ~isreal(k) ||...
    ~isfinite(k) || (k ~= round(k)))

    error(message('MATLAB:parfor:InvalidSlicedVariableOffset',...
          varname,...
          doclink('/toolbox/parallel-computing/distcomp_ug.map', ...
          'ERR_PARFOR_SLICED_OFFSET',...
          'Parallel Computing Toolbox, "parfor"')));
end
end
