function inputGroupProperties = getInputGroupProperties(inputGroups)
    inputGroupProperties = struct('SyntaxType', {}, 'isNameValuePair', {});
    for i = 1:numel(inputGroups)
        firstInput = inputGroups(i).Inputs(1);
        inputGroupProperties(i).SyntaxType = firstInput.SyntaxType;
        inputGroupProperties(i).isNameValuePair = firstInput.isNameValuePair;
    end
end
%   Copyright 2025 The MathWorks, Inc.