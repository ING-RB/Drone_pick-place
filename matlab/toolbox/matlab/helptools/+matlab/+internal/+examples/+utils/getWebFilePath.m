function webFilePath = getWebFilePath(component, filename)
%

%   Copyright 2020 The MathWorks, Inc.

    rootUrl = 'https://ssd.mathworks.com/supportfiles/';
    webFilePath = [rootUrl,component,'/',filename];
end
