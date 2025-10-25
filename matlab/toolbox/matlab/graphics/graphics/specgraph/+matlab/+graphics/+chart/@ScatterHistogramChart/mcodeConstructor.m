function mcodeConstructor(sh, code)
% Generate code to recreate the scatterhistogram.

%   Copyright 2018 The MathWorks, Inc.

% Call the superclass mcodeConstructor to handle position properties.
mcodeConstructor@matlab.graphics.chart.internal.SubplotPositionableChartWithAxes(sh, code);

% Use the 'scatterhistogram' command to create ScatterHistogramChart objects.
setConstructorName(code, 'scatterhistogram');

% Remove the table properties from the list of name-value pairs. They will
% be added later if necessary.
ignoreProperty(code, 'SourceTable');
ignoreProperty(code, 'XVariable');
ignoreProperty(code, 'YVariable');
ignoreProperty(code, 'GroupVariable');

% Check for table vs. matrix workflow.
if ~sh.UsingTableForData
    % Matrix syntax
    %   scatterhistogram(xdata, ydata, Name, Value)
    addArgument(sh, code, 'XData', 'xdata')
    addArgument(sh, code, 'YData', 'ydata')

    ignoreProperty(code, 'GroupData');
    
    if ~isempty(sh.GroupData)
        % Add GroupData property name argument.
        arg = codegen.codeargument('Value', 'GroupData', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);

        % Add GroupData property value argument.
        arg = codegen.codeargument('Name', 'GroupData', 'Value', sh.GroupData, ...
            'IsParameter', true, 'Comment', 'GroupData', ...
            'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
else
    % Table syntax
    %   scatterhistogram(tbl, xvar, yvar, Name, Value)
    
    % Add the SourceTable input argument.
    addArgument(sh, code, 'SourceTable', 'tbl')
    
    % Add the XVariable and YVariable input arguments.
    addArgument(sh, code, 'XVariable', 'xvar')
    addArgument(sh, code, 'YVariable', 'yvar')
    
    ignoreProperty(code, 'XData');
    ignoreProperty(code, 'YData');
    ignoreProperty(code, 'GroupData');
    
    % Process the GroupVariable
    if ~isempty(sh.GroupVariable)
        % GroupVariable is not empty, so add the GroupVariable input
        % argument as a name-value pair. Specify it as a parameter so that
        % it is used as an input argument in the generated code.
        
        % Add GroupVariable property name argument.
        arg = codegen.codeargument('Value', 'GroupVariable', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);
        
        % Add GroupVariable property value argument.
        arg = codegen.codeargument('Name', 'GroupVariable', 'Value', sh.GroupVariable, ...
            'IsParameter', true, 'Comment', 'GroupVariable', ...
            'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
end

% Remove properties that match defaults but have been repmatted to equal
% num groups
props = {'MarkerSize','MarkerAlpha','MarkerStyle','LineWidth'};
dflts = {36,1,"o",0.5};
for p = 1:length(props)
    propName = props{p};
    if all(sh.(propName) == dflts{p})
        ignoreProperty(code, propName);
    end
end

% Properties like NumBins are originally set to [] and are then populated
% during the chart's computation. Since the computed values will never
% match the defaults (but can be computed again merely by setting to [])
% check against a mode property to see if they were set by the user
props = {'XLimits','YLimits','NumBins','BinWidths','XLabel','YLabel',...
    'LegendTitle','Color','LegendVisible','LineStyle'};
for p = 1:length(props)
    propName = props{p};
    if strcmp(sh.([propName,'Mode']),'auto')
        ignoreProperty(code, propName);
    end
end

% Add the remaining name-value pair arguments.
generateDefaultPropValueSyntax(code);
end

function addArgument(hObj, code, prop, name)
% Add a convenience argument.

% Add the input argument.
arg = codegen.codeargument('Name', name, 'Value', hObj.(prop), ...
    'IsParameter', true, 'Comment', prop);
addConstructorArgin(code, arg);

% Ignore the property so it is not added twice.
ignoreProperty(code, prop);
end
