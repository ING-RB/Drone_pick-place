function preferencesFolder = getCacheFolderLocation(varargin)
%% getCacheFolderLocation Returns path to dir above 'rosbagViewer' cache folder
% In order to reduce cache drool during testing we wrap the prefdir call in
% a function we can override.
%

%   Copyright 2024 The MathWorks, Inc.

% Create a wrapper around prefdir
preferencesFolder = prefdir(varargin{:});

end