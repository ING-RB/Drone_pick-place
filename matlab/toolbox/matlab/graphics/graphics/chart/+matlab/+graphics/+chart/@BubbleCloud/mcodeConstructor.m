function mcodeConstructor(obj,code)
% Call the superclass mcodeConstructor to handle Position and
% Parent properties, and subplot.
mcodeConstructor@matlab.graphics.chart.internal.PositionableChartWithAxes(obj,code)

% Use bubblecloud() command to create objects
setConstructorName(code, 'bubblecloud')

if strcmp(obj.SizeDataMode,'manual')
    % Vector mode
    arg=codegen.codeargument('Name', 'sz', 'Value', obj.SizeData, ...
        'IsParameter', true, 'Comment', 'SizeData');
    addConstructorArgin(code, arg);

    % Note that groupdata is checked because a placeholder is
    % required when calling bubblecloud with group and no label
    if ~isempty(obj.LabelData) || ~isempty(obj.GroupData)
        arg=codegen.codeargument('Name', 'lbl', 'Value', obj.LabelData, ...
            'IsParameter', true, 'Comment', 'LabelData');
        addConstructorArgin(code, arg);
    end
    if ~isempty(obj.GroupData)
        arg=codegen.codeargument('Name', 'gp', 'Value', obj.GroupData, ...
            'IsParameter', true, 'Comment', 'GroupData');
        addConstructorArgin(code, arg);
    end
else
    % Table mode
    arg=codegen.codeargument('Name', 'tbl', 'Value', obj.SourceTable, ...
        'IsParameter', true, 'Comment', 'SourceTable');
    addConstructorArgin(code, arg);

    arg=codegen.codeargument('Name', 'szvar', 'Value', obj.SizeVariable, ...
        'IsParameter', true, 'Comment', 'SizeVariable');
    addConstructorArgin(code, arg);

    if ~isempty(obj.LabelVariable)
        arg=codegen.codeargument('Name', 'lblvar', 'Value', obj.LabelVariable, ...
            'IsParameter', true, 'Comment', 'LabelVariable');
        addConstructorArgin(code, arg);
    end
    if ~isempty(obj.GroupVariable)
        arg=codegen.codeargument('Name', 'gpvar', 'Value', obj.GroupVariable, ...
            'IsParameter', true, 'Comment', 'GroupVariable');
        addConstructorArgin(code, arg);
    end
end
% Ignore all table and data properties (which are handled as
% arguments)
ignoreProperty(code, 'SizeData');
ignoreProperty(code, 'LabelData');
ignoreProperty(code, 'GroupData');
ignoreProperty(code, 'SourceTable');
ignoreProperty(code, 'SizeVariable');
ignoreProperty(code, 'LabelVariable');
ignoreProperty(code, 'GroupVariable');

% Add the remaining name-value pair arguments.
generateDefaultPropValueSyntax(code);
end
