function range_step_check(varname, step)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2017-2019 The MathWorks, Inc.
%
% The step of parfor-loop must evaluate to the scalar integer 1.
%
% The isscalar test ensures that all other tests return a scalar logical.
% The functions isfinite and round can produce non-scalar results.
if (~isscalar(step) || ~isnumeric(step) || ~isreal(step) ||...
    ~isfinite(step) || step ~= 1)...

    error(message('MATLAB:parfor:InvalidParforLoopRangeStep',...
          varname,...
          doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
          'ERR_PARFOR_RANGE',...
          'parfor-Loops in MATLAB, "parfor"')));
end
end
