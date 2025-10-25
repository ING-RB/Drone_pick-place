function obj = loadobj(S)
%loadobj
%

%   Copyright 2022 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TabularBuilder.ClassVersion
            error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
        end
    end

    obj = matlab.io.internal.common.builder.TabularBuilder();
    % Override with the actual options.
    obj.Options = S.Options;
end
