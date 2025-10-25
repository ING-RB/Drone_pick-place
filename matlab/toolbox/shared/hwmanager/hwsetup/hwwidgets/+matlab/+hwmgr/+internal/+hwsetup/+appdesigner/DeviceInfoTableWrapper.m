classdef DeviceInfoTableWrapper < matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper
    %DEVICEINFOTABLEWRAPPER Provides implementation of the Peer interface and
    %provides the management of the various UIComponents that make up the
    %DeviceInfoTable functionality.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access = 'public')
        Labels = {'Device Info 1', 'Device Info 2', 'Device Info 3'};
        Values = {'Value 1', 'Value 2', 'Value 3'};
    end
    
    methods
        function obj = DeviceInfoTableWrapper(varargin)
            %DeviceInfoTableWrapper- constructor
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper(varargin{:});
        end
        
        function formatTextForDisplay(obj)
            % FORMATTEXTFORDISPLAY uses DeviceInfoTableWrapper properties to 
            % construct the HTML table for display
            
            beginDoc = ['<html>' obj.getStylesheet() '<body><table>'];
            numRows = max(numel(obj.Values), numel(obj.Labels));
            htmlTable = cell(numRows, 1);
            [htmlTable{:}] = deal('');
            iValues = cell(numRows, 1);
            iLabels = cell(numRows, 1);
            iValues(1:numel(obj.Values)) = obj.Values;
            iLabels(1:numel(obj.Labels)) = obj.Labels;
            
            for i = 1:numRows
                htmlTable{i} = ['<tr><td style="background-color:var(' matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorSecondary ');'...
                    'width: 1px;white-space: nowrap;">'...
                    iLabels{i} '</td><td>' iValues{i} '</td></tr>'];
            end
            
            if isempty(htmlTable)
                tablecontents = '';
            else
                htmlTable = cellfun(@join, htmlTable, 'UniformOutput', false);
                tablecontents = strjoin(htmlTable);
            end
            endDoc = ['</table>' obj.getScript() '</body></html>'];
            
            formattedString = [ beginDoc tablecontents endDoc ];
            
            obj.HTMLComponent.HTMLSource = formattedString;
        end
    end
    
    %setters
    methods
        function set.Values(obj, values)
            obj.Values = values;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
        
        function set.Labels(obj, labels)
            obj.Labels = labels;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
    end
end