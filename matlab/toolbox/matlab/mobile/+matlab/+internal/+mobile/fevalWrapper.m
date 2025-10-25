function encodedOutput = fevalWrapper(jsonblob)
%

%   Copyright 2023 The MathWorks, Inc.

    try
      jsonblob = jsondecode(jsonblob);
      [functionName, numberOfOutputs, rhsArgs] = parseInputJson(jsonblob);
      [output{1:numberOfOutputs}] = feval(functionName, rhsArgs{:});
      encodedOutput = jsonencode(output{:});
    catch ME
        throwAsCaller(ME)
    end
end

function [functionName, numberOfOutputs, rhsArgs] = parseInputJson(p)
    rhsArgs = p.arguments;
    functionName = p.function;
    numberOfOutputs = p.nargout;
end
