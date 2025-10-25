function sd = getSupportFileDir
% 

%   Copyright 2020 The MathWorks, Inc.

ed = matlab.internal.examples.getExamplesDir();
sd = fullfile(ed, 'supportfiles');
end

