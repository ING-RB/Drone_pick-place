function yes = openJavaApp(flag)
%

% This is a temporary function for switching between Java and JS app. By
% default, it returns true to open the existing Java-based app container.
% Provide input flag to change it to JS app.

%  Copyright 2021 The MathWorks, Inc.

persistent bool
if isempty(bool)
    bool = false;
end
if nargin == 1
    bool = flag;
end

yes = bool;
end