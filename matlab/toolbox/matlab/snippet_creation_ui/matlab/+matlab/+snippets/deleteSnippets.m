function deleteSnippets()
% DELETESNIPPETS Delete snippets in the MATLAB environment.
%
% This function serves as a wrapper to delete code snippets in the MATLAB
% environment by calling an internal function.
%

%   Copyright 2024 The MathWorks, Inc.

    % Call the internal function to delete snippets
    matlab.internal.snippets.DeleteSnippets();
end