function focus(obj)
    %FOCUS Focus UI component
    %
    %   FOCUS(c) gives keyboard focus to the UI component c and brings its parent figure to the front
    %
    %   See also UIFIGURE, UITABLE, UIBUTTON, UIEDITFIELD
    
    %   Copyright 2021 The MathWorks, Inc.
    
    % focus is not supported with Java figure
    if ~matlab.ui.internal.isUIFigure(obj)
        error(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
            'figure'));
    end

    % warn and do not focus when Visible property is 'off'
    if strcmp(obj.Visible, 'off')
        msgTxt = getString(message('MATLAB:ui:components:FigureNotFocusable'));
        mnemonicField = 'FigureNotFocusable';
        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
        return;
    end

    % Make sure the view is up to date and the controller exists
    matlab.graphics.internal.drawnow.startUpdate;
    
    controller = obj.Controller;

    % Focus UIFigure
    controller.bringToFocus();
end