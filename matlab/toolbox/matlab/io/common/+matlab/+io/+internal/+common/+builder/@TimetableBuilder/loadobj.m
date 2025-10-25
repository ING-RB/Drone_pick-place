function obj = loadobj(S)
%loadobj
%

%   Copyright 2022 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TimetableBuilder.ClassVersion
            error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
        end
    end

    % Construct the object with some dummy parameters that should be valid
    % already.
    obj = matlab.io.internal.common.builder.TimetableBuilder(VariableNames=S.Options.TableBuilder.VariableNames, ...
                                                     RowTimesVariableIndex=S.Options.RowTimesVariableIndex);
    % Override with the actual options.
    obj.Options = S.Options;
end
