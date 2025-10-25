function varargout = TableCellPropsDialog_cb( dlg, action, varargin )

switch action
    
    case 'doFillColor'
        colorIndex = dlg.getWidgetValue('TABLECELLPROPS_COLOR');
        fcUserData = dlg.getUserData('TABLECELLPROPS_COLOR');
                
        if colorIndex == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
            if fcUserData.index == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
                color = GLUE2.Util.invokeColorPicker(fcUserData.color);
            else
                color = GLUE2.Util.invokeColorPicker;
            end
            
            % on cancel of custom color dialog, result will be empty
            if ~isempty(color)
                fcUserData.index = TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM;
                fcUserData.color = color;
                dlg.setUserData('TABLECELLPROPS_COLOR', fcUserData);
            else
                dlg.setWidgetValue('TABLECELLPROPS_COLOR', fcUserData.index);
            end
        else
            fcUserData.index = colorIndex;
            dlg.setUserData('TABLECELLPROPS_COLOR', fcUserData);
        end
end

varargout{1} = 1;
varargout{2} = '';
