function mapfile = ctrlguihelp(topickey,varargin)
%CTRLGUIHELP  Help support for Control System Toolbox GUIs.

%   Copyright 1986-2022 The MathWorks, Inc.

if nargin
    % Pass help topic to help browser
    try
        helpview('control',topickey);
    end
end
