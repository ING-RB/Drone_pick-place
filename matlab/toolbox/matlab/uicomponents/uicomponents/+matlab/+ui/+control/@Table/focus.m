function focus(obj)
    %FOCUS Focus UI component
    %
    %   FOCUS(c) gives keyboard focus to the UI component c and brings its parent figure to the front
    %
    %   See also UIFIGURE, UITABLE, UIBUTTON, UIEDITFIELD
    
    %   Copyright 2021 The MathWorks, Inc.

    % focus is not supported with tables parented to a figure
    if ~matlab.ui.control.internal.model.TablePropertyHandling.isValidComponent(obj)
        error(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
            'figure'));
    end

    % warn and do not focus when: 
    % Visible property is 'off'
    % Enable property is 'off' or 'inactive'
    if strcmp(obj.Visible, 'off')
        msgTxt = getString(message('MATLAB:ui:components:NotFocusable',...
            'Visible','off'));
        mnemonicField = 'NotFocusable';
        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
        return;
    elseif any(strcmp(obj.Enable, {'off','inactive'}))
        msgTxt = getString(message('MATLAB:ui:components:NotFocusable',...
            'Enable','off'));
        mnemonicField = 'NotFocusable';
        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
        return;
    end
    
    topLevelAncestor = ancestor(obj, 'figure', 'toplevel');
    if ~isempty(topLevelAncestor)
        % warn and do not focus when parent figure is invisible
        if strcmp(topLevelAncestor.Visible, 'off')
            msgTxt = getString(message('MATLAB:ui:components:FigureNotFocusable'));
            mnemonicField = 'FigureNotFocusable';
            matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
            return;
        end

        % Otherwise, bring the parent figure to front
        figure(topLevelAncestor);
    end

    % Make sure the view is up to date and the controller exists
    matlab.graphics.internal.drawnow.startUpdate;

    controller = obj.Controller;

    % Focus UITable
    controller.bringToFocus();
end