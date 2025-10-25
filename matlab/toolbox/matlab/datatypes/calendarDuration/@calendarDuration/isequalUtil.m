function args = isequalUtil(args)
%

%ISEQUALUTIL Convert calendarDurations into values that can be compared directly with isequal.
%   ARGS = ISEQUALUTIL(ARGS) converts the calendarDurations in cell array
%   ARGS into corresponding values that can be compared directly with
%   isequal.

%   Copyright 2014-2024 The MathWorks, Inc.

try

    for i = 1:length(args)
        arg = args{i};
        if isa(arg, 'missing')
            arg = calendarDuration(arg);
        elseif ~isa(arg,'calendarDuration')
            error(message('MATLAB:calendarDuration:InvalidComparison',class(arg),'calendarDuration'));
        end
        % Expand out scalar zero placeholders to simplify comparison of all three
        % fields. May also have to put appropriate nonfinites into elements of
        % fields that were expanded.
        args{i} = calendarDuration.adjustComponentsForComparision(arg.components);
    end

catch ME
    throwAsCaller(ME);
end
