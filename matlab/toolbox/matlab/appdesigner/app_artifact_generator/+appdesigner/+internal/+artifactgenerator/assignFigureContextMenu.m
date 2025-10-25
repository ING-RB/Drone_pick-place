function assignFigureContextMenu(codeBuilder, figureCodeName, componentProperties)
    %ASSIGNFIGURECONTEXTMENU after both figure and context menus have been created,
    % then write the codeline that assigns the context menu to uifigure

%   Copyright 2024 The MathWorks, Inc.

    arguments
        codeBuilder appdesigner.internal.artifactgenerator.AppMCodeBuilder
        figureCodeName string
        componentProperties
    end

    import appdesigner.internal.artifactgenerator.AppendixConstants;

    count = length(componentProperties);

    for i = 1:count
        if strcmp(componentProperties(i).PropertyName, 'ContextMenu')
            codeBuilder.addCodeLine(append(AppendixConstants.GeneratedCodeAppObjectName, '.', figureCodeName, '.ContextMenu = ',...
                AppendixConstants.GeneratedCodeAppObjectName, '.', strrep(componentProperties(i).PropertyValue, '''', ''), ';'));
            break;
        end
    end
end
