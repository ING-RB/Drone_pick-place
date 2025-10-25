function mcodeConstructor(pc, code)
% Generate code to recreate the parallelplot.

%   Copyright 2018 The MathWorks, Inc.

% Call the superclass mcodeConstructor to handle position properties.
mcodeConstructor@matlab.graphics.chart.internal.PositionableChartWithAxes(pc, code);

% Use the 'parallelplot' command to create ParallelCoordinatesPlot objects.
setConstructorName(code, 'parallelplot');

% Remove the table properties from the list of name-value pairs. They will
% be added later if necessary.
ignoreProperty(code, 'SourceTable');
ignoreProperty(code, 'CoordinateVariables');
ignoreProperty(code, 'GroupVariable');

% Check for table vs. matrix workflow.
if ~pc.UsingTableForData
    % Matrix syntax
    %   parallelplot(data, Name, Value)
    addArgument(pc, code, 'Data', 'data')
    
    ignoreProperty(code, 'CoordinateData');
    ignoreProperty(code, 'GroupData');
    
    % Add the CoordinateData N-V pair only if explicitly changed by the
    % user. Otherwise parallelplot plots all columns
    if strcmp(pc.CoordinateDataMode,'manual')
        % Add CoordinateData property name argument.
        arg = codegen.codeargument('Value', 'CoordinateData', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);

        % Add CoordinateData property value argument.
        arg = codegen.codeargument('Name', 'CoordinateData', 'Value',...
            pc.CoordinateData, 'IsParameter', true, 'Comment',...
            'CoordinateData', 'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
    
    % Add GroupData N-V pair if set by user
    if ~isempty(pc.GroupData)
        % Add GroupData property name argument.
        arg = codegen.codeargument('Value', 'GroupData', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);

        % Add GroupData property value argument.
        arg = codegen.codeargument('Name', 'GroupData', 'Value', pc.GroupData, ...
            'IsParameter', true, 'Comment', 'GroupData', ...
            'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
else
    % Table syntax
    %   parallelplot(tbl, Name, Value)
    
    % Add the SourceTable input argument.
    addArgument(pc, code, 'SourceTable', 'tbl')
    
    % Ignore properties that only apply to matrix data
    ignoreProperty(code, 'Data');
    ignoreProperty(code, 'CoordinateData');
    ignoreProperty(code, 'GroupData');
    
    % Process the CoordinateVariables only if explicitly changed by user.
    % Otherwise parallelplot plots all table columns
    if strcmp(pc.CoordinateDataMode,'manual')
        % CoordinateVariables is not empty, so add the CoordinateVariables
        % input argument as a name-value pair. Specify it as a parameter so
        % that it is used as an input argument in the generated code
        
        % Add CoordinateVariables property name argument.
        arg = codegen.codeargument('Value', 'CoordinateVariables', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);
        
        % Add GroupVariable property value argument.
        arg = codegen.codeargument('Name', 'CoordinateVariables', 'Value',...
            pc.CoordinateVariables, 'IsParameter', true, 'Comment',...
            'CoordinateVariables', 'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
    
    % Process the GroupVariable if one is set by the user
    if ~isempty(pc.GroupVariable)
        % GroupVariable is not empty, so add the GroupVariable input
        % argument as a name-value pair. Specify it as a parameter so that
        % it is used as an input argument in the generated code
        
        % Add GroupVariable property name argument.
        arg = codegen.codeargument('Value', 'GroupVariable', ...
            'ArgumentType', codegen.ArgumentType.PropertyName);
        addConstructorArgin(code, arg);
        
        % Add GroupVariable property value argument.
        arg = codegen.codeargument('Name', 'GroupVariable', 'Value', pc.GroupVariable, ...
            'IsParameter', true, 'Comment', 'GroupVariable', ...
            'ArgumentType', codegen.ArgumentType.PropertyValue);
        addConstructorArgin(code, arg);
    end
end

% Remove properties that match defaults but have been repmatted to equal
% num groups
props = {'MarkerSize','LineWidth','LineAlpha'};
dflts = [6,1,0.7];
for p = 1:length(props)
    propName = props{p};
    if all(pc.(propName) == dflts(p))
        ignoreProperty(code, propName);
    end
end

% Check against a mode property to see if property was set by the user,
% otherwise ignore it
props = {'CoordinateLabel','DataLabel','LegendTitle','Color',...
    'LegendVisible','LineStyle','MarkerStyle','CoordinateTickLabels'};
for p = 1:length(props)
    propName = props{p};
    if strcmp(pc.([propName,'Mode']),'auto')
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
