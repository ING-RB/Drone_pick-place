function [ctorAssignment, extra, postChildren, isCallback] = translateProperty(codeName, prop, callbackFunctions, className, isUac, isLoad)
    %TRANSLATEPROPERTY some properties such as "XLabel.String" needs to call a function instead of being a
    % constructor argument, when those edge-cases are found, they're called "extra lines". This function
    % makes that determination and returns the proper execution line of code or the assignment argued to the 
    % component constructor

%   Copyright 2024 The MathWorks, Inc.

    arguments
        codeName
        prop
        callbackFunctions
        className
        isUac logical
        isLoad logical = false
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    ctorAssignment = '';
    extra = '';
    postChildren = '';
    isCallback = false;

    switch (prop.PropertyName)
        case 'XLabel.String'
            extra = buildFcnExtraCodeLine('xlabel', AppendixConstants.GeneratedCodeAppObjectName, codeName, appdesigner.internal.artifactgenerator.sanitizeComponentPropertyValue(prop.PropertyValue));

        case 'YLabel.String'
            extra = buildFcnExtraCodeLine('ylabel', AppendixConstants.GeneratedCodeAppObjectName, codeName, appdesigner.internal.artifactgenerator.sanitizeComponentPropertyValue(prop.PropertyValue));

        case 'ZLabel.String'
            extra = buildFcnExtraCodeLine('zlabel', AppendixConstants.GeneratedCodeAppObjectName, codeName, appdesigner.internal.artifactgenerator.sanitizeComponentPropertyValue(prop.PropertyValue));

        case 'Title.String'
            extra = buildFcnExtraCodeLine('title', AppendixConstants.GeneratedCodeAppObjectName, codeName, appdesigner.internal.artifactgenerator.sanitizeComponentPropertyValue(prop.PropertyValue));

        case {'Layout.Row', 'Layout.Column'}
            extra = buildExtraAssignment(AppendixConstants.GeneratedCodeAppObjectName, codeName, prop.PropertyName, prop.PropertyValue);

        case 'ImageSource'
            ctorAssignment = buildImageAssignmentCodeLine(prop.PropertyName, prop.PropertyValue);

        case 'Icon'
            ctorAssignment = buildIconAssignmentCodeLine(prop.PropertyName, prop.PropertyValue);
        
        case 'ContextMenu'
            ctorAssignment = append(prop.PropertyName, '=', AppendixConstants.GeneratedCodeAppObjectName, '.', strrep(prop.PropertyValue, '''', ''));

        case 'CheckedNodes'
            postChildren = buildTreeNodeSelectionAssignment(codeName, prop.PropertyName, prop.PropertyValue);

        case 'SelectedNodes'
            postChildren = buildTreeNodeSelectionAssignment(codeName, prop.PropertyName, prop.PropertyValue);
        
        otherwise
            if isCallbackProperty(prop.PropertyName, callbackFunctions, className, isUac)
                isCallback = true;
                
                if isLoad
                    ctorAssignment = append(prop.PropertyName, '=', '''', prop.PropertyValue, '''');
                else
                    % Passing callback as component constructor argument would make
                    % it executed during model creation, however, at that point,
                    % app.(CodeName) property in an app's instance is not assigned yet,
                    % therefore, callback would error out on referring to app.(CodeName)
                    % object.
                    callbackFcnValue = append('@(src,e)', AppendixConstants.AppManagementServiceVariable, '.executeCallback(app, @(obj, event)app.', strrep(prop.PropertyValue, '''', ''), '(event), true, e)');
                    extra = buildExtraAssignment(AppendixConstants.GeneratedCodeAppObjectName, codeName, prop.PropertyName, callbackFcnValue);
                end
            else
                ctorAssignment = append(prop.PropertyName, '=', char(appdesigner.internal.artifactgenerator.sanitizeComponentPropertyValue(prop.PropertyValue)));
            end
    end
end

function postChildren = buildTreeNodeSelectionAssignment(codeName, prop, value)
    import appdesigner.internal.artifactgenerator.AppendixConstants;

    nodes = strsplit(strrep(strrep(value, ']', ''), '[', ''), ' ');
    referencedNodes = cellfun(@(x)append(AppendixConstants.GeneratedCodeAppObjectName, '.', x), nodes, 'UniformOutput', false);
    postChildren = append(AppendixConstants.GeneratedCodeAppObjectName, '.', codeName, '.', prop, ' = ', '[', strjoin(referencedNodes, ' '), '];');
end

function codeline = buildIconAssignmentCodeLine (propName, propValue)
    [newValue, iconType] = matlab.ui.internal.IconUtils.validateIcon(strrep(propValue, '''', ''));

    if strcmp(iconType, 'preset')
        codeline = append(propName, '=', '''', newValue, '''');
    else
        codeline = buildImageAssignmentCodeLine(propName, propValue);
    end
end

function codeline = buildImageAssignmentCodeLine (propName, propValue)
    if logical(exist(strrep(propValue, '''', ''), 'file'))
        codeline = append(propName, '=', propValue);
    else
        codeline = append(propName, '=', 'fullfile(', appdesigner.internal.artifactgenerator.AppendixConstants.PathToAppFileVariable, ', ', propValue, ')');
    end
end

function codeline = buildFcnExtraCodeLine (fcn, objName, codeName, value)
    codeline = append(fcn, '(', objName, '.', codeName, ', ', value, ');');
end

function codeline = buildExtraAssignment (objName, codeName, propertyName, value)
    codeline = append(objName, '.', codeName, '.', propertyName, ' = ', value, ';');
end

function isPresent = isCallbackProperty (propertyName, callbackFunctions, className, isUac)
    isPresent = false;

    if ~isUac
        count = length(callbackFunctions);
        for i = 1:count
            if strcmp(callbackFunctions(i).CallbackName, propertyName)
                isPresent = true;
                break;
            end
        end
    else
        isPresent = isUacCallbackFunction(className, propertyName);
    end
end

function isUacCallback = isUacCallbackFunction (className, propertyName)
    isUacCallback = false;

    metaClass = eval(append('?', className));

    if ~isempty(metaClass)
        uacCallbacks = appdesigner.internal.usercomponent.extractCallbackPropertyNamesFromMetaClass(metaClass);
    
        count = length(uacCallbacks);
        for i = 1:count
            if strcmp(uacCallbacks{i}, propertyName)
                isUacCallback = true;
                break;
            end
        end
    else
        error(message('MATLAB:appdesigner:appdesigner:AppAppendixUnknownComponent', className));
    end
end
