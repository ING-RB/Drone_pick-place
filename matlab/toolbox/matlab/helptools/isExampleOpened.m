function exampleOpened = isExampleOpened(id)
%

%   Copyright 2021 The MathWorks, Inc.

% Parse the input.
p = inputParser;
addRequired(p,'id', @(x) validateattributes(x,{'char','string'},{'nonempty'}));
parse(p, id);
id = p.Results.id;

[id, ~] = matlab.internal.examples.identifyExample(id);
metadata = findExample(id);
workDir = matlab.internal.examples.getWorkDir(metadata);
exampleOpened = matlab.internal.examples.folderExists(workDir);
end

function b = bool2char(x)
    tf_words = {'false','true'};
    b = tf_words{x+1};
end

