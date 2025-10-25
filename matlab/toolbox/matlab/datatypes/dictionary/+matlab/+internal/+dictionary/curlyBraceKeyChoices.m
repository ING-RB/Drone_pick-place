function choices = curlyBraceKeyChoices(d)
% Used to offer suggested keys for dictionaries with cell value type

%   Copyright 2022 The MathWorks, Inc.

    [~,valueType] = types(d);
    
    if valueType == "cell"
        choices = matlab.internal.dictionary.functionSignatureChoices(d);
    else
        choices = {};
    end
end
