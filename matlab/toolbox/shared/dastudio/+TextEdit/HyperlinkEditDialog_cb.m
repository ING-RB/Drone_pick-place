function varargout = HyperlinkEditDialog_cb( dlg, action, varargin )
% HyperlinkEditDialog_cb: A callback for the hyperlink dialog.
%   The purpose of this callback is to control which widget should be
%   enabled and what text needs to be displayed in the annotation in 
%   case the user did not select text before launching the dialog.
switch action
    
    case 'doTextEdit'
        text = dlg.getWidgetValue('HYPERLINK_TEXT');
        textud = dlg.getUserData('HYPERLINK_TEXT');
        if (isempty(text))
            % text widget is empty, we need to create it from the
            % code widget if the user leaves it blank. we need also 
            % to replace the selection with its value
            textud.createText = true;
            textud.replaceText = true;            
            dlg.setUserData('HYPERLINK_TEXT', textud);            
        elseif (textud.createText && ~strcmp(text, textud.text))
            % text widget value is different from its created value. we 
            % need to stop creating its value but we still need to replace 
            % the selection with its value
            textud.createText = false;
            textud.replaceText = true;
            dlg.setUserData('HYPERLINK_TEXT', textud);
        elseif (~textud.replaceText)
            % the text widget had a value from the selection but now it's
            % changed. we need to replace the selection with its value
            textud.replaceText = true;
            dlg.setUserData('HYPERLINK_TEXT', textud);            
        end
   
    case 'doCodeEdit'
        code = dlg.getWidgetValue('HYPERLINK_CODE');
        textud = dlg.getUserData('HYPERLINK_TEXT');
        
        if (textud.createText)
            % copy the value of the code widget to the text widget
            dlg.setWidgetValue('HYPERLINK_TEXT', code);
            textud.text = code;
            dlg.setUserData('HYPERLINK_TEXT', textud);
        end
        
end

varargout{1} = 1;
varargout{2} = '';
