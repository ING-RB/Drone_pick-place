%   Abstract file chooser

%   Copyright 2022 The MathWorks, Inc. 
classdef FileChooser
    % Interface to choose a file
    methods (Abstract)
        [filenames, pathname] = browseFiles(obj, filter, messageText, startDir)
        pathname = browseFolders(obj, startDir, messageText)
    end
end
