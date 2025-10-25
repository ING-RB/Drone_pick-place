function [localName, found] = getCaseCorrectLocalName(fullName, localName)
    [~, mainFunctionName] = fileparts(fullName);
    % Note: -subfun is an undocumented and unsupported feature
    localFunctions     = [{mainFunctionName}; which('-subfun', fullName)];
    localFunctionIndex = matches(localFunctions, localName);

    found = any(localFunctionIndex);

    if ~found
        localFunctionIndex = matches(localFunctions, localName, IgnoreCase=true);
        found = any(localFunctionIndex);
    end

    if found
        localFunctionIndex = find(localFunctionIndex, 1);
        localName = localFunctions{localFunctionIndex};
    end
end

%   Copyright 2024 The MathWorks, Inc.
