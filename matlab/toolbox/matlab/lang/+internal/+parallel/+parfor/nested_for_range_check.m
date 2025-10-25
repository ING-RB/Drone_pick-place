function nested_for_range_check(varname, range)
%

% Copyright 2017-2019 The MathWorks, Inc.
%
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% When indexing sliced variables, the range of a nested for-loops variables must
% evaluate to a row vector of positive integers.

if ~isempty(range)

    if ~isnumeric(range) || (~isreal(range) && any(imag(range),'all')) || any(~isfinite(range),'all')

        error(message('MATLAB:parfor:InvalidNestedForLoopRangeValue',...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
            'ERR_PARFOR_FOR_RANGE',...
            'parfor-Loops in MATLAB, "Nested for-Loops with Sliced Variables"')));
    end

    if ~isrow(range)

        error(message('MATLAB:parfor:InvalidNestedForLoopRangeDimensions',...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
            'ERR_PARFOR_FOR_RANGE',...
            'parfor-Loops in MATLAB, "Nested for-Loops with Sliced Variables"')));
    end

    if any(range <= 0) || any(range ~= round(range))
        error(message('MATLAB:parfor:InvalidNestedForLoopRangeValue',...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map',...
            'ERR_PARFOR_FOR_RANGE',...
            'parfor-Loops in MATLAB, "Nested for-Loops with Sliced Variables"')));
    end

end
