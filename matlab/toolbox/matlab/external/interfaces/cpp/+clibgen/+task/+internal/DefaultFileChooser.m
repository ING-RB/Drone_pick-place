%   Default file chooser

%   Copyright 2022 The MathWorks, Inc.
classdef DefaultFileChooser < clibgen.task.internal.FileChooser
    methods
        function  [filenames, pathname] = browseFiles(~, filter, messageText, startDir)
            [filenames, pathname] = uigetfile(filter, messageText, ...
                                              'MultiSelect','on', startDir);
        end
        function pathname = browseFolders(~, startDir, messageText)
            pathname = uigetdir(startDir, messageText);
        end
    end
end
