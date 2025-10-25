function createSnippets()
% CREATESNIPPETS Create snippets in the MATLAB environment.
%
% This function serves as a wrapper to create code snippets in the MATLAB
% environment by calling an internal function.
%

%   Copyright 2024 The MathWorks, Inc.

    % Call the internal function to create snippets
    matlab.internal.snippets.CreateSnippets();
end
