function str=getDatatipString(obj,dataind,labelColor,valueColor)
%

%   Copyright 2020-2024 The MathWorks, Inc.

arguments
    obj
    dataind
    labelColor
    valueColor
end


% Get a datatip string for a bubble, use the table variable name if in
% table mode.

hassizes=~isempty(obj.SizeData_I);
if ~hassizes
    str=[];
    return
end

haslabels=~isempty(obj.LabelData_I);
hasgroups=~isempty(obj.GroupData_I);

hassizevar=~isempty(obj.SizeVariable_I);
haslabelvar=~isempty(obj.LabelVariable_I);
hasgroupvar=~isempty(obj.GroupVariable_I);

% Make sure we have valid colors. These will be empty in the case of a
% figure without a theme.
if isempty(labelColor) 
    labelColor = [.25 .25 .25];
end
if isempty(valueColor)
    valueColor = [0 0.6 1];
end

labelColorStr = mat2str(labelColor);
valueColorStr = mat2str(valueColor);
texLabel=sprintf('\\color[rgb]{%s}\\rm', labelColorStr(2:end-1));
texValue=sprintf('\\color[rgb]{%s}\\bf', valueColorStr(2:end-1));

if hassizevar
    tipLabel=obj.SizeVariableName;
else
    tipLabel=getString(message('MATLAB:graphics:bubblecloud:DatatipSize'));
end
tipValue=string(obj.SizeData_I(dataind));

str=sprintf("{%s%s} {%s%s}",texLabel,tipLabel,texValue,tipValue);

if haslabels
    if haslabelvar
        tipLabel=obj.LabelVariableName;
    else
        tipLabel=getString(message('MATLAB:graphics:bubblecloud:DatatipLabel'));
    end
    tipValue=getTipValue(obj.LabelData_I(dataind));
    str=[str sprintf("{%s%s} {%s%s}",texLabel,tipLabel,texValue,tipValue)];
end

if hasgroups
    if hasgroupvar
        tipLabel=obj.GroupVariableName;
    else
        tipLabel=getString(message('MATLAB:graphics:bubblecloud:DatatipGroup'));
    end
    tipValue=getTipValue(obj.GroupData_I(dataind));
    str=[str sprintf("{%s%s} {%s%s}",texLabel,tipLabel,texValue,tipValue)];
end
end

function str=getTipValue(data)
% return a string containing data, marking missing data as <missing> or NaN
% depending on the data type
str=string(data);
if ismissing(str) 
    if isnumeric(data)
        str="NaN";
    else
        str="<missing>";
    end
end
end

