function editSnippets()
% EDITSNIPPETS Edit snippets in the MATLAB environment.
%
% This function serves as a wrapper to edit code snippets in the MATLAB
% environment by calling an internal function.
%

%   Copyright 2024 The MathWorks, Inc.

    % Call the internal function to edit snippets
    matlab.internal.snippets.EditSnippets();
end