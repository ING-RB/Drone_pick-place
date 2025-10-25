function selectionString = var2string(selectedData)

% Create an array of strings based on the selectedData array.

%   Copyright 2007-2024 The MathWorks, Inc.

selectionString = '';
% Use a tab separated list to ensure paste-ability to Variable Editor
if ~isempty(selectedData)
    
    if isnumeric(selectedData)
        selectionString = mat2str(selectedData);   
        selectionString = regexprep(selectionString,'^\[|\]$','');
        selectionString(selectionString == ' ') = sprintf('\t');
        selectionString(selectionString == ';') = sprintf('\n');
    else
        if ~iscell(selectedData)
            selectedData = {selectedData};
        end
        % Create a string array [xdata,ydata[,zdata]]
        strdata = string(selectedData{1});
        for col=2:numel(selectedData)
             strdata = [strdata,string(selectedData{col})]; %#ok<AGROW>
        end
        % Create an array of strings one for each element [xdata(row),ydata(row)[,zdata(row)]]
        % with a tab separating each value
        for row=1:size(strdata,1)
            strrows(row) = strjoin(strdata(row,:),'\t'); %#ok<AGROW>
        end
        % Concatenate strings representing rows using a newline
        selectionString = char(strjoin(strrows,'\n'));
    end
end