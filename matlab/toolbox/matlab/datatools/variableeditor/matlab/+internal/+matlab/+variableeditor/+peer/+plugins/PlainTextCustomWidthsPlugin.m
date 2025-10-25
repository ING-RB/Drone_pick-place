classdef PlainTextCustomWidthsPlugin < internal.matlab.variableeditor.peer.plugins.CustomWidthsPlugin
  %CUSTOMWIDTHSPLUGIN 
    % This plugin computes custom widths based on cell contents (that are just strings and non-JSON data)
    % and sets them as columnModelProps 
    
    % Copyright 2019 The MathWorks, Inc.   
    
    methods
        
        % getParsedCellData is used to fetch contents from the rendererdData
        % assuming that data is in plain text format.
        function cellData = getParsedCellData(~, renderedData)
            cellData = renderedData;
        end
    end
end

