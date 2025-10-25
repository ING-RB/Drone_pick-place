classdef WidgetDefaults < handle
    %WIDGETDEFAULTS is a class that defines the default properties for HW
    %Setup widgets. If user does not define a property for a widget, the 
    %property value  will be set using the data available in this class.
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Constant)
        PanelTitle = 'My Panel Title';
        ButtonText = 'MyButton';
        CheckBoxText = 'MyCheckBox';
        HTMLText = 'MyHTMLText';
        RadioButtonText = 'MyRadioButton';
        LabelText = 'MyLabel';
        RadioGroupTitle = 'MyRadioGroup';
        
        UIControlPosition = [20 20 100 20];
        CheckBoxPosition = [20 45 95 20];
        HTMLTextPosition = [20 250 100 100];
        LabelPosition = [20 70 70 20];
        
        ProgressBarPosition = [300 300 100 20];
        ProgressBarValue = 0;
        ProgressBarIndeterminate = false;
        
        EditTextText = '';
        EditTextPosition = [300 300 100 20];
        EditTextTextAlignment = 'center';
        EditTextFontSize = 12;
        EditTextFontWeight = 'normal';
        EditTextVisible = 'off';
        
        LabelFontSize = 12;
        LabelFontWeight = 'normal';
        LabelTextAlignment = 'left';
        
        %If a screen takes longer to load, default placeholder text may be 
        %displayed to users. We make it empty to avoid this.
        HelpTextAboutSelection = '';
        HelpTextWhatToConsider = '';
        HelpTextAdditional = '';
        
        TpDownloadTablePosition = [20 200 400 80];
        TpDownloadTableName = {'Tool 1', 'Tool 2'};
        TpDownloadTableVersion = {'5.2.1', '3.4'};
        TpDownloadTableDetails = {'<a href="https://www.mathworks.com">Download</a>', 'No Download Required'};
        TpDownloadTextAlignment = 'center';
    end
    
    methods(Static)
        function out = getDefaultWindowPosition()
            out = [matlab.hwmgr.internal.hwsetup.util.Layout.getWindowDistFromLeftEdge()...
                matlab.hwmgr.internal.hwsetup.util.Layout.getWindowDistFromBottomEdge()...
                matlab.hwmgr.internal.hwsetup.util.Layout.HWSetupWindowWidth ...
                matlab.hwmgr.internal.hwsetup.util.Layout.HWSetupWindowHeight];
            % if screen size is smaller than the default minimum, use
            % screen size, else creating a window will throw an error.
            if (out(1) < 1) || (out(2) < 1)
                [w, h] = matlab.hwmgr.internal.hwsetup.util.Layout.getScreenDimensions();
                out = [1, 1, w, h];
            end
        end
    end
end