classdef ThemeMixin < handle
    % THEMEMIXIN - mixin class for the Theme property of
    % UIFigure

    % Copyright 2024 The MathWorks, Inc.

    properties(SetObservable = true)
        Theme
        ThemeMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
    end

    methods
        function set.Theme(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if isprop(obj.OriginalObjects(end), 'Theme') && ~isempty(obj.OriginalObjects(end).Theme)
                    if isa(inspectorValue, "matlab.graphics.theme.GraphicsTheme")
                        inspectorValue = inspectorValue.BaseColorStyle;
                    elseif isa(inspectorValue, "inspector.internal.datatype.Theme")
                        inspectorValue = char(inspectorValue);
                    end
                    if ~isequal(obj.OriginalObjects(idx).Theme.BaseColorStyle, char(inspectorValue))
                        obj.OriginalObjects(idx).Theme = char(inspectorValue); %#ok<*MCNPR>
                    end
                end
            end
        end

        function value = get.Theme(obj)
            value = '';
            if isprop(obj.OriginalObjects(end), 'Theme') && ~isempty(obj.OriginalObjects(end).Theme)
                value = inspector.internal.datatype.Theme.(obj.OriginalObjects(end).Theme.BaseColorStyle);
            end
        end
    end
end
