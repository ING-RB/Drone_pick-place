classdef StatusTableWrapper < ...
        matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper
    % STATUSTABLEWRAPPER - wrapper specific for StatusTable. It
    % provides all api's exposed by HTMLTableWrapper and makes changes
    % required for StatusTable.
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Access = 'public')
        Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass,...
                matlab.hwmgr.internal.hwsetup.StatusIcon.Fail,...
                matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
        Steps =  {'Step 1', 'Step 2', 'Step 3'};
        Border = 'on';
    end
    
    methods
        function obj = StatusTableWrapper(aParent)
            %StatusTableWrapper- construct StatusTableWrapper and set
            %defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper(aParent);
        end
        
        function formatTextForDisplay(obj)
            % FORMATTEXTFORDISPLAY uses StatusTableWrapper properties to 
            % construct the HTML table for display
            
            styleSheet = obj.getStylesheet();
            if strcmp(obj.Border, 'off')
               styleSheet = strrep(styleSheet, obj.BorderStyle, '');
            end
            beginDoc = ['<html>' styleSheet '<body><table>'];
            
            numRows = max(numel(obj.Steps), numel(obj.Status));
            htmlTable = cell(numRows, 1);
            [htmlTable{:}] = deal('');
            iSteps = cell(numRows, 1);
            iStatus = cell(numRows, 1);
            iSteps(1:numel(obj.Steps)) = obj.Steps;
            iStatus(1:numel(obj.Status)) = obj.Status;
            
            for i = 1:numRows
                if isa(iStatus{i}, 'matlab.hwmgr.internal.hwsetup.StatusIcon')
                    icon = iStatus{i}.dispIcon();
                else
                    icon = iStatus{i};
                end
                htmlTable{i} = ['<tr><td style="width:20px; word-wrap: break-word">' icon '</td><td style="width:410px; word-wrap: break-word">' iSteps{i} '</td></tr>'];
            end
            if isempty(htmlTable)
                tablecontents = '';
            else
                htmlTable = cellfun(@join, htmlTable, 'UniformOutput', false);
                tablecontents = strjoin(htmlTable);
            end
            endDoc = ['</table>' obj.getScript() '</body></html>'];
            
            formattedString = [beginDoc tablecontents endDoc];
            obj.HTMLComponent.HTMLSource = char(join(formattedString));
        end
    end
    
    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.Status(obj, status)
            obj.Status = status;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
        
        function set.Steps(obj, steps)
            obj.Steps = steps;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
        
        function set.Border(obj, border)
            obj.Border = border;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
    end
end