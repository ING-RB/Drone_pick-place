function S = saveobj(obj)
%saveobj
%

%   Copyright 2022 The MathWorks, Inc.

    % Store save-load metadata.
    S = struct("EarliestSupportedVersion", 1);
    S.ClassVersion = obj.ClassVersion;

    % State properties
    S.Options = obj.Options;
end
