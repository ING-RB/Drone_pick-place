function obj = loadobj(S)
%loadobj
%

%   Copyright 2022 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TableBuilder.ClassVersion
            error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
        end
    end

    % Nothing should have happened in transit that requires
    % another cross-validation step here. So avoid doing it again.
    obj = matlab.io.internal.common.builder.TableBuilder();
    obj.Options = S.Options;
end
