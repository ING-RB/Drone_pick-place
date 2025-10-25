function varargout = TablePropsDialog_cb( dlg, action, varargin )

switch action
    
    case 'doBorderColor'
        colorIndex = dlg.getWidgetValue('TABLEPROPS_COLOR');
        bcUserData = dlg.getUserData('TABLEPROPS_COLOR');
                
        if colorIndex == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
            if bcUserData.index == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
                color = GLUE2.Util.invokeColorPicker(bcUserData.color);
            else
                color = GLUE2.Util.invokeColorPicker;
            end
            
            % on cancel of custom color dialog, result will be []
            if ~isempty(color)
                bcUserData.index = TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM;                
                bcUserData.color = color;
                dlg.setUserData('TABLEPROPS_COLOR', bcUserData);
            else
                dlg.setWidgetValue('TABLEPROPS_COLOR', bcUserData.index);
            end
        else
            bcUserData.index = colorIndex;
            dlg.setUserData('TABLEPROPS_COLOR', bcUserData);
        end
end

varargout{1} = 1;
varargout{2} = '';
