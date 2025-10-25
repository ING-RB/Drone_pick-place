function demoTopic = getDemoTopic(hp)
    demoTopic = '';
    fullTopic = matlab.lang.internal.introspective.safeWhich(hp.fullTopic);
    [path, name] = fileparts(fullTopic);
    if isfile(fullfile(path, 'html', append(name, '.html')))
        minimalTopic = matlab.lang.internal.introspective.minimizePath(fullTopic, false);
        [path, name] = fileparts(minimalTopic);
        demoTopic = replace(fullfile(path, name), '\', '/');
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.
