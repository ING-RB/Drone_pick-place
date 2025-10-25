classdef (Abstract) mcodeConstructorHelper
    % A collection of Static methods that can be used by the
    % mcodeConstructor for chart objects that subclass from
    % matlab.graphics.mixin.DataProperties.

    % Copyright 2021-2022 The MathWorks, Inc.

    methods (Static)
        function [channels, propertyNames] = getPositionalArguments(obj, channels, matrixSyntaxes, tableSyntaxes)
            % Determine which matrix or table syntaxes can be used to
            % reconstruct the object based on which visual channels have
            % data, and whether that data came from a table or not.
            %
            % channels is a string vector listing all the visual channels
            % for the specified object.
            %
            % matrixSyntaxes is an MxN logical matrix reflecting valid
            % matrix syntaxes. Each column represents a visual channel, and
            % there should be one column per visual channel. Each row
            % represents a valid syntax. A true value indicates that visual
            % channel is required for that syntax. The first row that
            % includes a syntax that matches the current object will be
            % used. A "matching syntax" means that the required visual
            % channels have DataMode properties that are 'manual' and Data
            % properties that are non-empty.
            %
            % tableSyntaxes is similarly an MxN logical matrix reflecting valid
            % table syntaxes. Each column represents a visual channel, and
            % there should be one column per visual channel. Each row
            % represents a valid syntax. A true value indicates that visual
            % channel is required for that syntax. The first row that
            % includes a syntax that matches the current object will be
            % used. A "matching syntax" means that the required visual
            % channels return true from isDataComingFromDataSource.

            arguments
                % The object to recreate in the generate code.
                obj (1,1) matlab.graphics.mixin.DataProperties

                % A list of all the visual channels.
                channels (1,:) string

                % Logical matrix reflecting valid matrix syntaxes.
                matrixSyntaxes (:,:) logical

                % Logical matrix reflecting valid table syntaxes.
                tableSyntaxes (:,:) logical
            end

            % Figure out which channels are using data from a table.
            usingTable = isDataComingFromDataSource(obj, channels);

            % Loop through the table syntaxes to see if a match is found:
            for n = 1:height(tableSyntaxes)
                syntax = tableSyntaxes(n,:);
                if all(usingTable(syntax))
                    channels = ["" channels(syntax)];
                    propertyNames = ["SourceTable", channels(2:end)+"Variable"];
                    return
                end
            end

            % Figure out which channels are using data from a matrix.
            [usingMatrix, propertyNames] = isManualAndNonEmpty(obj, channels);

            % Loop through the matrix syntaxes to see if a match is found:
            for n = 1:height(matrixSyntaxes)
                syntax = matrixSyntaxes(n,:);
                if all(usingMatrix(syntax)) || n == height(matrixSyntaxes)
                    channels = channels(syntax);
                    propertyNames = propertyNames(syntax);
                    return
                end
            end
        end

        function [objs, momentoList] = findCompatibleObjects(obj, code, channels)
            % Find objects with compatible data that can be created with a
            % single call to the convenience function. "Compatible" means
            % the data is the same length for matrix input, it needs
            % the same signature, and has the same parent.

            arguments
                % The object to recreate in the generate code.
                obj (1,1) matlab.graphics.mixin.DataProperties

                % The codegen.codeblock object used to generate code.
                code (1,1) codegen.codeblock

                % A list of all the visual channels.
                channels (1,:) string
            end

            import matlab.graphics.chart.primitive.internal.mcodeConstructorHelper

            % Initialize outputs
            objs = obj;
            objMomento = code.MomentoRef;
            momentoList = objMomento;

            % Don't merge objects if any data is coming from a table.
            if any(isDataComingFromDataSource(obj, channels))
                return
            end

            % Find objects with the same Parent.
            parentMomento = up(objMomento);
            if ~isempty(parentMomento)
                momentoList = findobj(parentMomento,'-depth',1);
                objs = gobjects(1, numel(momentoList));
            end

            % Find compatible objects.
            compatible = false(1, numel(momentoList));
            thisIndex = 1;
            usingMatrix = isManualAndNonEmpty(obj, channels);
            for n = 1:numel(compatible)
                peerMomento = momentoList(n);
                peerObj = peerMomento.ObjectRef;
                if isempty(peerObj)
                    compatible(n) = false;
                    continue
                end
                objs(n) = peerObj;

                if peerObj == obj
                    compatible(n) = true;
                    thisIndex = n;
                else
                    compatible(n) = ...
                        ~peerMomento.Ignore && ...
                        ~hasCustomConstructor(peerObj) && ...
                        isequal(obj.NodeParent, peerObj.NodeParent) && ...
                        strcmp(class(obj), class(peerObj)) && ...
                        numel(obj.YData_I) == numel(peerObj.YData_I) && ...
                        isequal(usingMatrix, isManualAndNonEmpty(peerObj, channels));
                end

                % Ignore compatible objects.
                if compatible(n)
                    peerMomento.Ignore = true;
                end
            end

            % Remove incompatible objects and make sure the original object
            % is the first object in the list.
            objs(thisIndex) = [];
            compatible(thisIndex) = [];
            momentoList(thisIndex) = [];
            objs = [obj objs(compatible)];
            momentoList = [objMomento; momentoList(compatible)];
        end

        function generateCode(objs, code, channels, positionalChannels, propertyNames, momentoList, collapsableChannels)
            % Generate MATLAB code to recreate the specified object.
            %
            % This function is designed to be called from the
            % mcodeConstructor for an object that subclasses from
            % matlab.graphics.mixin.DataProperties.
            %
            % Prior to calling this function, call getPositionalArguments
            % to get the positionalChannels and propertyNames inputs, and
            % call setConstructorName on the codegen.codeblock object to
            % set the constructor name.
            %
            % obj and code are the inputs provided to the mcodeConstructor.
            %
            % channels is a string vector listing all the visual channels
            % for the specified object.
            %
            % positionalChannels and propertyNames are the outputs from
            % getPositionalArguments. They are expected to be string
            % vectors of equal length representing the channels and
            % property names used for positional arguments.

            arguments
                % The object(s) to recreate in the generate code.
                objs (1,:) matlab.graphics.mixin.DataProperties

                % The codegen.codeblock object used to generate code.
                code (1,1) codegen.codeblock

                % A list of all the visual channels.
                channels (1,:) string

                % Channels used as positional arguments.
                positionalChannels (1,:) string

                % Property names used as positional arguments.
                propertyNames (1,:) string

                % List of momento objects corresponding to the list of
                % objects that will be merged into a single function call.
                momentoList (1,:) = []

                % Channels that can be collapsed from a matrix to a vector.
                collapsableChannels (1,:) string = positionalChannels
            end

            import matlab.graphics.chart.primitive.internal.mcodeConstructorHelper

            % Generate the basic starting code.
            primaryObject = objs(1);
            plotutils('makemcode', primaryObject, code)

            % Add positional arguments to the generated code.
            mcodeConstructorHelper.addPositionalArguments(objs, code, positionalChannels, propertyNames, collapsableChannels);

            % Add input arguments corresponding to non-positional data
            % properties.
            mcodeConstructorHelper.makeParameterIfManual(primaryObject, code, setdiff(channels, positionalChannels));

            % Add variable properties as name/value pairs if necessary.
            mcodeConstructorHelper.addVariableNameValuePairs(primaryObject, code, channels, positionalChannels);

            if isscalar(objs)
                % Add remaining name/value pairs to the generated code.
                generateDefaultPropValueSyntax(code);
            else
                % Customize the output argument to indicate it will be a
                % vector of objects.
                func = getConstructor(code);
                arg = codegen.codeargument( ...
                    'Value', objs, ...
                    'Name', func.Name);
                addArgout(func,arg);

                % Add a comment about creating multiple objects.
                constructorName = code.Constructor.Name;
                typeName = primaryObject.Type;
                func.Comment = getString( ...
                    message('MATLAB:specgraph:mcodeConstructor:CreateMultipleObjectsUsingMatrix', ...
                    typeName, constructorName));

                % Generate set calls for each individual object.
                codetoolsswitchyard('mcodePlotObjectVectorSet', ...
                    code, momentoList, @isDataSpecificProperty);
            end
        end

        function addPositionalArguments(objs, code, channels, propertyNames, collapsableChannels)
            % Add input arguments and parameters for each positional
            % property. These could be SourceTable, Data properties, or
            % Variable properties.

            arguments
                % The object(s) to recreate in the generate code.
                objs (1,:) matlab.graphics.mixin.DataProperties

                % The codegen.codeblock object used to generate code.
                code (1,1) codegen.codeblock

                % Channels used as positional arguments.
                channels (1,:) string

                % Property names used as positional arguments.
                propertyNames (1,:) string

                % Channels that can be collapsed from a matrix to a vector.
                collapsableChannels (1,:) string = channels
            end

            multipleObjects = numel(objs) > 1;
            primaryObject = objs(1);
            for n = 1:numel(propertyNames)
                channel = channels(n);
                propertyName = propertyNames(n);
                [renamedProperty, argumentName, comment] = getNameAndComment( ...
                    primaryObject, code.Constructor.Name, channel, propertyName, multipleObjects);

                % Ignore the property when generating name/value pairs.
                code.ignoreProperty(cellstr([propertyName renamedProperty]));
                value = primaryObject.(renamedProperty);

                if endsWith(propertyName, "Data")
                    matrixData = false;
                    if multipleObjects
                        % For multiple objects, merge the data into a
                        % single matrix.
                        try
                            % Collect the data from each of the objects.
                            value = NaN(numel(value), numel(objs));
                            for o = 1:numel(objs)
                                value(:,o) = objs(o).(renamedProperty)(:);
                            end

                            % Check if the data from all the objects was
                            % exactly the same. If so, collapse it back
                            % down into a vector.
                            matrixData = true;
                            if any(channel == collapsableChannels) && all(value(:,1) == value,'all')
                                value = value(:,1);
                                matrixData = false;

                                % Regenerate the argument name and comment.
                                [renamedProperty, argumentName, comment] = ...
                                    getNameAndComment(primaryObject, ...
                                    code.Constructor.Name, ...
                                    channel, propertyName, false);
                            end
                        catch
                            % If the object is in an inconsistent state,
                            % and the data values are different lengths,
                            % fall-back to the first object's data.
                            value = primaryObject.(renamedProperty);
                        end
                    end
    
                    if ~matrixData
                        % For Data properties, check if there is a
                        % corresponding DataSource property. If so, get the
                        % parameter name from the DataSource property.
                    
                        % Ignore the DataSource properties.
                        code.ignoreProperty(cellstr([propertyName, renamedProperty]+ "Source"));
    
                        % Determine the argument name from the DataSource
                        % property.
                        if isprop(primaryObject, propertyName + "Source_I")
                            argumentName = code.cleanName(primaryObject.(propertyName + "Source_I"), argumentName);
                        end
                    end
                end

                arg = codegen.codeargument( ...
                    'Name', argumentName, ...
                    'Value', value, ...
                    'IsParameter', true, ...
                    'Comment', comment);

                addConstructorArgin(code,arg);
            end
        end

        function makeParameterIfManual(obj, code, channels)
            % Add an input argument (parameter) corresponding to data
            % properties that are manual but were not included as
            % positional arguments.

            arguments
                obj (1,1) matlab.graphics.mixin.DataProperties
                code (1,1) codegen.codeblock
                channels (1,:) string
            end

            % Find out which channels have Mode='manual' and are not empty.
            [usingMatrix, propertyNames] = isManualAndNonEmpty(obj, channels);

            for c = 1:numel(channels)
                if usingMatrix(c)
                    channel = channels(c);
                    propertyName = char(getNameAndComment(obj, '', channel, propertyNames(c)));

                    % Make sure the property exists and is not Ignored.
                    code.addProperty(propertyName);

                    % Make sure the property is included as a parameter.
                    prop = findobj(code.MomentoRef.PropertyObjects, 'Name', propertyName);
                    prop.IsParameter = true;
                end
            end
        end

        function addVariableNameValuePairs(obj, code, channels, positionalChannels)
            % Add name/value pairs corresponding to the SourceTable and any
            % Variable properties that were not included as positional
            % arguments. When necessary, set the corresponding Mode
            % property to 'auto' before setting the Variable property.

            arguments
                obj (1,1) matlab.graphics.mixin.DataProperties
                code (1,1) codegen.codeblock
                channels (1,:) string
                positionalChannels (1,:) string
            end

            % Find all the properties in the list of momento's and which
            % ones are being ignored.
            momentoPropertyNames = {code.MomentoRef.PropertyObjects.Name};
            unignoredInd = ~[code.MomentoRef.PropertyObjects.Ignore];
            unignoredProperties = momentoPropertyNames(unignoredInd);

            % Find all the variable properties that are not being ignored.
            variablePropertyNames = channels + "Variable";
            found = ismember(variablePropertyNames, unignoredProperties);
            variablePropertyNames = variablePropertyNames(found);
            channels = channels(found);

            % If there's a SourceTable, make that a parameter and make sure
            % it comes before all the variable properties.
            found = strcmp(momentoPropertyNames, 'SourceTable');
            if any(found)
                code.MomentoRef.PropertyObjects(found).IsParameter=true;
                code.movePropertyBefore('SourceTable', cellstr(variablePropertyNames));
            end

            % Loop through the variable properties and make sure they are
            % listed as parameters, and the corresponding modes are toggled
            % if necessary.
            for i = 1:numel(variablePropertyNames)
                propName = variablePropertyNames(i);

                % If the property is empty, ignore it.
                if isempty(obj.(propName))
                    code.ignoreProperty(cellstr(propName));
                    continue
                end

                % The mode will be manual if the corresponding data
                % property was a positional data input. To set the
                % variable, the code must toggle the mode back to 'auto'.
                if ismember(channels(i), positionalChannels)
                    modePropName = channels(i) + "DataMode";
                    if channels(i) == "Color"
                        modePropName = "CDataMode";
                    end
                    code.addProperty(modePropName);
                    code.movePropertyBefore(char(modePropName), char(propName));
                end

                % Make the property a parameter.
                found = strcmp({code.MomentoRef.PropertyObjects.Name}, propName);
                code.MomentoRef.PropertyObjects(found).IsParameter = true;
            end
        end
    end
end

function [tf, propNames] = isManualAndNonEmpty(obj, channels)
% Check the data property and mode corresponding to each channel to
% determin whether the mode is 'manual' and the data is not empty.

arguments
    obj (1,1) matlab.graphics.mixin.DataProperties
    channels (1,:) string
end

propNames = channels;
tf = false(size(channels));
for c = 1:numel(channels)
    propNames(c) = channels(c) + "Data";

    % Use "CData" instead of "ColorData".
    if channels(c) == "Color"
        propNames(c) = "CData";
    end

    % Check if the channel is non-empty with Mode = 'manual'.
    modeName = propNames(c) + "Mode";
    tf(c) = ~isempty(obj.(propNames(c))) && isequal(obj.(modeName), 'manual');
end

end

function [propertyName, argumentName, comment] = getNameAndComment(obj, constructorName, channel, propertyName, multipleObjects)
% Generate the property name and comment for code generation.

arguments
    obj (1,1) matlab.graphics.mixin.DataProperties
    constructorName (1,1) string
    channel (1,1) string
    propertyName (1,1) string
    multipleObjects (1,1) logical = false
end

[xyorz, loc] = ismember(channel,["X" "Y" "Z"]);
if xyorz
    channel = obj.DimensionNames{loc};
end

if propertyName == "SourceTable"
    argumentName = "tbl";
    comment = sprintf('%s Source Table', constructorName);
elseif endsWith(propertyName, "Variable")
    propertyName = channel + "Variable";
    argumentName = channel + "Var";
    comment = sprintf('%s %s Variable', constructorName, channel);
elseif endsWith(propertyName, "Data")
    propertyName = channel + "Data";
    if channel == "Color"
        propertyName = "CData";
    end
    if multipleObjects
        argumentName = channel + "Matrix";
        comment = getString( ...
            message('MATLAB:specgraph:mcodeConstructor:CommentMatrixOfData', ...
            constructorName, channel));
    else
        argumentName = channel;
        comment = getString( ...
            message('MATLAB:specgraph:mcodeConstructor:CommentVectorOfData', ...
            constructorName, channel));
    end
end

% Code generation doesn't work well with a mix of strings and character
% vectors. Make sure the argument name is a character vector so that when
% combined with other argument names in a cell array, the resulting cell
% array is still a cellstr.
argumentName = char(argumentName);

end

function tf = hasCustomConstructor(obj)
% Determine whether the peer object should be ignored due to the presence
% of a custom constructor.

tf = false;
info = getappdata(obj, 'MCodeGeneration');
if isstruct(info) && isfield(info, 'MCodeConstructorFcn')
    fcn = info.MCodeConstructorFcn;
    if ~isempty(fcn)
        tf = true;
    end
else
    hb = hggetbehavior(obj, 'MCodeGeneration', '-peek');
    if ~isempty(hb)
        fcn = get(hb, 'MCodeConstructorFcn');
        if ~isempty(fcn)
            tf = true;
        end
    end
end

end

function flag = isDataSpecificProperty(~, property)
% This helper function is used by mcodePlotObjectVectorSet when generating
% name/value pairs for calls to set on individual members of a vector of
% objects. Returning true causes the property to be skipped. The current
% implementation skips data (and variable) related properties because they
% require special handling.

name = string(property.Name);
flag = endsWith(name, "Data") || ...
        endsWith(name, "DataMode") || ...
        endsWith(name, "DataSource") || ...
        endsWith(name, "Variable");

end
