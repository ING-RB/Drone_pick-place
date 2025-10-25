function viewSnippets()
% VIEWSNIPPETS View snippets in the MATLAB environment.
%
% This function serves as a wrapper to view code snippets in the MATLAB
% environment by calling an internal function.
%

%   Copyright 2024 The MathWorks, Inc.

    % Call the internal function to view snippets
    matlab.internal.snippets.ViewSnippets();
end
