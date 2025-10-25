function len = vectorizedWrappedLength(s, showHyperlinks)
% Wrapper around matlab.internal.display.wrappedLength that works on text
% arrays instead of just scalar text.
%
% For text containing markup (e.g. <strong> tags or <a> tags),
% vectorizedWrappedLength returns the length of the text as it displays in
% the current context (i.e. desktop vs. headless).

%   Copyright 2022-2023 The MathWorks, Inc.

arguments
    s
    showHyperlinks = matlab.display.internal.isHotlinksSupported;
end

len = zeros(size(s));
for i = 1:numel(s)
    len(i) = matlab.internal.display.wrappedLength(s(i), showHyperlinks);
end
