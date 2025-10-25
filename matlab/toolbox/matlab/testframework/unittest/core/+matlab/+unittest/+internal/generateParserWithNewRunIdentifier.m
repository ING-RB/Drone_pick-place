function parser = generateParserWithNewRunIdentifier()
% This function is undocumented and may change in a future release.

% Copyright 2016-2019 The MathWorks, Inc.

import matlab.lang.internal.uuid;

parser = matlab.unittest.internal.strictInputParser;
parser.addParameter('RunIdentifier', uuid, @isValidRunIdentifier);
end

function bool = isValidRunIdentifier(value)
import matlab.unittest.internal.mustBeTextScalar;
import matlab.unittest.internal.validatePathname;
mustBeTextScalar(value);
bool = true;
try
    validatePathname(fullfile(tempdir,value));
catch
    bool = false;
end
bool = bool && ~contains(value,["/","\"," "]);
end
