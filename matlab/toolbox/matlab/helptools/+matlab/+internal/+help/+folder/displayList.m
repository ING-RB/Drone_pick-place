function varargout = displayList(topic, varargin)
    list = matlab.internal.help.folder.getOthersList(topic);
    emptyListID = 'MATLAB:helpUtils:displayHelp:NoFoldersNamed';
    
    [varargout{1:nargout}] = matlab.internal.help.displayOtherNamesList(topic, list, emptyListID, varargin{:});
end

%   Copyright 2020-2024 The MathWorks, Inc.
