function reduction_variables_set_check(varargin)
%

% Copyright 2017-2019 The MathWorks, Inc.
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% Reduction variables must exist before the parfor-loop executes.
for idx = 1:2:numel(varargin)
    varname = varargin{idx};
    varExists = varargin{idx+1};
    if ~varExists
        error(message('MATLAB:parfor:UninitializedReductionVariable',...
            varname,...
            doclink('/toolbox/parallel-computing/distcomp_ug.map', ...
            'ERR_PARFOR_REDUCTION_VARIABLE',...
            'parfor-Loops in MATLAB, "parfor"')));
    end
end
end
