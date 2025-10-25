classdef (Abstract) demoFileHandlerFactory
    %  MATLAB.INTERNAL.DOC.PROJECT.DEMOFILEHANDLERFACTORY

    %   Copyright 2020 The MathWorks, Inc.
    
    methods(Abstract, Access=public)
        loc_exists = locationExists()
        file_exists = fileExists()
        backupDemoFile()
        str = readDemoFile()
        writeDemoFile(newStr)
    end    
end