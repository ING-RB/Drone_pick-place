classdef RptFileBase< handle
%RptFileBase Base class for RptFile classes

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=RptFileBase
        end

        function out=getHoleContent(~) %#ok<STOUT>
            % Returns the content to fill the Content hole in the template
        end

        function out=loadSetupFile(~) %#ok<STOUT>
            % Loads the report setup file in the internal CReport property
        end

    end
    properties
        % SetupFile Report setup file
        %    Specifies the name or path of the Report Explorer setup (.rpt)
        %    file.
        SetupFile;

    end
end
