classdef SampleSlider < handle
    %    DAStudio.SampleSlider properties:
    %       Path - Property is of type 'ustring'  (read only) 
    %       sliderProp - Property is of type 'int32'  
    %       dialProp - Property is of type 'int32'  
    %       spinnerProp - Property is of type 'int32'  
    %       toggleProp - Property is of type 'bool'  
    %
    %    DAStudio.SampleSlider methods:
    
    properties (SetObservable)
        %SLIDERPROP Property is of type 'int32' 
        sliderProp (1,1) int32 = 5;
        %DIALPROP Property is of type 'int32' 
        dialProp (1,1) int32 = 16;
        %SPINNERPROP Property is of type 'int32' 
        spinnerProp (1,1) int32 = 10;
        %TOGGLEPROP Property is of type 'bool' 
        toggleProp (1,1) logical = true;
    end
    
    methods

        % constructor
        function this = SampleSlider()
        end

        function dlgstruct = getDialogSchema(h, name)

              %%%%%%%%%%%%%%%%%%%%%%%
              % slider widget horizontal
              %%%%%%%%%%%%%%%%%%%%%%%    
              slider1.Tag = 'slider1';
              slider1.Type = 'slider';
              slider1.TickInterval = 4;
              slider1.TickPosition = 'below';
              slider1.Orientation = 'horizontal';  
              slider1.Range = [0 100];
              slider1.ObjectProperty = 'sliderProp';
              slider1.RowSpan = [1 1];
              slider1.ColSpan = [2 3];
              slider1.Mode  = 1;
              slider1.DialogRefresh  = 1;
              slider1.ObjectMethod = 'sliderCallback';
              slider1.MethodArgs = {'%dialog', slider1.Tag};
              slider1.ArgDataTypes = {'handle', 'string'};
              slider1.ToolTip = 'slider tooltip';
              slider1.SliderReleasedCallback = @SliderReleasedCB;
              slider1.Tracking = false;
            
              sliderLabel.Type = 'text';
              sliderLabel.Name = ['Slider:' '(', num2str(h.sliderProp), ')'];
              sliderLabel.Buddy = slider1.Tag;
              sliderLabel.RowSpan = [1 1];
              sliderLabel.ColSpan = [1 1];
                
              sliderMinLabel.Type = 'text';
              sliderMinLabel.Name = '0';
              sliderMinLabel.Alignment = 5; %center left
              sliderMinLabel.RowSpan = [2 2];
              sliderMinLabel.ColSpan = [2 2];
              
              sliderMaxLabel.Type = 'text';
              sliderMaxLabel.Name = '100';
              sliderMaxLabel.Alignment = 7; %center right
              %sliderMaxLabel. MaximumSize = [30 20];
              sliderMinLabel.RowSpan = [3 3];
              sliderMinLabel.ColSpan = [2 2];
              
              sliderGroup.Type = 'group';
              %sliderGroup.Name = 'Slider group';
              sliderGroup.LayoutGrid = [2 3];
              sliderGroup.ColStretch = [0 1 1];
              sliderGroup.RowSpan = [1 1];
              sliderGroup.ColSpan = [1 3];
              sliderGroup.Items = {sliderLabel, slider1, sliderMinLabel, sliderMaxLabel};
                
              %%%%%%%%%%%%%%%%%%%%%%%
              % dial widget
              %%%%%%%%%%%%%%%%%%%%%%%    
              dial.Type = 'dial';  
              dial.Tag = 'dial'; 
              dial.Range = [1 100];
              dial.SingleStep = 2;
              dial.PageStep = 20;
              dial.NotchVisible = true; 
              dial.ObjectProperty = 'dialProp';
              dial.RowSpan = [1 1];
              dial.ColSpan = [2 3];
              dial.Mode  = 1;
              dial.DialogRefresh  = 1;
              dial.ObjectMethod = 'sliderCallback';
              dial.MethodArgs = {'%dialog', dial.Tag};
              dial.ArgDataTypes = {'handle', 'string'};
              dial.ToolTip = 'dial tooltip';
              dial.Tracking = false;
              dial.SliderReleasedCallback = @SliderReleasedCB;
              
              dialLabel.Type = 'text';
              %dialLabel.Name = 'Dial:';
              dialLabel.Name = ['Dial:' '(', num2str(h.dialProp), ')'];
              dialLabel.Buddy = dial.Tag;
              dialLabel.ColSpan = [1 1];
              dialLabel.RowSpan = [1 1];
              
              dialMinLabel.Type = 'text';
              dialMinLabel.Name = [num2str(dial.Range(1)), '    '];
              dialMinLabel.Alignment = 7; %center left
              %dialMinLabel.MaximumSize = [20 20]; 
              dialMinLabel.RowSpan = [2 2];
              dialMinLabel.ColSpan = [2 2];
              
              dialMaxLabel.Type = 'text';
              dialMaxLabel.Name = ['   ', num2str(dial.Range(2))];
              dialMaxLabel.Alignment = 5; %center right
              dialMaxLabel.RowSpan = [2 2];
              dialMaxLabel.ColSpan = [3 3];
                  
              dialGroup.Type = 'group';
              dialGroup.LayoutGrid = [2 3];
              dialGroup.ColStretch = [0 1 1];
              dialGroup.RowSpan = [2 2];
              dialGroup.ColSpan = [1 3];
              dialGroup.Items = {dial, dialLabel, dialMinLabel, dialMaxLabel};
              
              %%%%%%%%%%%%%%%%%%%%%%%
              % spinbox widget
              %%%%%%%%%%%%%%%%%%%%%%%      
              spinner.Tag = 'spinbox';
              spinner.Type = 'spinbox';  
              spinner.Range = [0 100];
              spinner.RowSpan = [1 1];
              spinner.ColSpan = [2 2];
              spinner.ObjectProperty = 'spinnerProp';
              spinner.Mode  = 1;
              spinner.DialogRefresh  = 1;
              spinner.ObjectMethod = 'sliderCallback';
              spinner.MethodArgs = {'%dialog', spinner.Tag};
              spinner.ArgDataTypes = {'handle', 'string'};
              spinner.ToolTip = 'spinner tooltip';
            %   spinner.Enabled = false;
            %   spinner.Editable = false;
              spinner.Tracking = true;
              spinner.ValidationCallback = @SpinboxTextValidate;
              
              spinnerLabel.Type = 'text';
              spinnerLabel.Name = 'SpinBox:';
              spinnerLabel.Buddy = spinner.Tag;
              spinnerLabel.RowSpan = [1 1];
              spinnerLabel.ColSpan = [1 1];      
              
              spinnerGroup.Type = 'group';
              spinnerGroup.LayoutGrid = [1 2];
              spinnerGroup.ColStretch = [0 1];
              spinnerGroup.RowSpan = [3 3];
              spinnerGroup.ColSpan = [1 3];  
              spinnerGroup.Items = {spinnerLabel, spinner};
            
              %%%%%%%%%%%%%%%%%%%%%%%
              % splitbutton widget
              %%%%%%%%%%%%%%%%%%%%%%%      
              split.Name = 'split button';
              split.Type = 'splitbutton';
              split.Tag = 'my_splitbutton';
              split.FilePath = [matlabroot '/toolbox/shared/dastudio/resources/new.png'];
            
              action1 = SampleActionBuilder('Open', [matlabroot '/toolbox/shared/dastudio/resources/open.png'], 'action1');
              action1.setEnabled(false);
              action2 = SampleActionBuilder('Save', [matlabroot '/toolbox/shared/dastudio/resources/save.png'], 'action2');
              split.ActionEntries = {action1, action2};
              split.DefaultAction = 'action2'; 
              split.UseButtonStyleForDefaultAction = true;
              %split.MaximumSize = [150, 50];
              split.ActionCallback = @actionCallback;  
              %split.ButtonStyle = 'icononly';
              %split.Enabled = false;
              %split.Visible = false;
              split.ToolTip = 'splitbutton with menu';
              split.RowSpan = [4 4];
              split.ColSpan = [1 1];  
              
            
            % No action entries, used as regular button
              split2.ToolTip = 'splitbutton tooltip';
              split2.RowSpan = [4 4];
              split2.ColSpan = [1 1];  
              
              %split2.Name = 'split button';
              split2.Type = 'pushbutton';%'splitbutton';
              split2.Tag = 'my_splitbutton2';
              split2.FilePath = [matlabroot '/toolbox/shared/dastudio/resources/new.png'];
              split2.ObjectMethod = 'buttonClickedCallback';
              split2.MethodArgs = {'%dialog', split2.Tag};
              split2.ArgDataTypes = {'handle', 'string'};
            
              split2.ToolTip = 'splitbutton without menu';
              split2.RowSpan = [4 4];
              split2.ColSpan = [2 2];  
              
              toggle.Name = 'toggle';
              toggle.FilePath = [matlabroot '/toolbox/shared/dastudio/resources/new.png'];
              toggle.Type = 'togglebutton';
              toggle.Tag = 'my_togglebutton';
              toggle.Value = true;
              toggle.WidgetId = 'my_togglebutton_Id';
              toggle.RowSpan = [5 5];
              toggle.ColSpan = [1 2];
              toggle.BackgroundColor = [200 100 100];
              toggle.ForegroundColor = [220 0 140];
            %   toggle.Enabled = false;
            %   toggle.Visible = false;
            
              %%%%%%%%%%%%%%%%%%%%%%%
              % matlab editor widget
              %%%%%%%%%%%%%%%%%%%%%%%        
              editor.Type = 'matlabeditor';
              editor.RowSpan = [1 5];
              editor.ColSpan = [4 4];
            % editor.Value = 'function callbackFunction(d, buttontag, actiontag)';
              editor.FilePath = [matlabroot '\toolbox\shared\dastudio\+DAStudio\sampleSliderCallback.m'];
              %editor.Enabled = false;  
            
              %%%%%%%%%%%%%%%%%%%%%%%
              % table widget
              %%%%%%%%%%%%%%%%%%%%%%%      
              button.Name           = 'Button';
              button.Type           = 'pushbutton';
            %   button.BackgroundColor = [200 200 50];
            %   button.ForegroundColor = [0 100 0];
              
              hyperlink.Name        = 'Hyperlink';
              hyperlink.Type        = 'hyperlink';
            %   hyperlink.BackgroundColor = [100 200 200];
            %   hyperlink.ForegroundColor = [100 100 200];
            
              edit.Name           = 'Edit';
              edit.Type           = 'edit';
              edit.Value = 'Editable edit';
            %   edit.BackgroundColor = [100 200 100];
            %   edit.ForegroundColor = [200 100 100];
            
              check.Name           = 'Checkbox';
              check.Type           = 'checkbox';
            %   check.BackgroundColor = [200 40 100];
            %   check.ForegroundColor = [200 50 150];
              
              combo.Type = 'combobox';
              combo.Entries = {'entry 1', 'entry 2'};
            %   combo.BackgroundColor = [200 200 30];
            %   combo.ForegroundColor = [0 255 0];
              
              text.Type = 'text';
              text.Name = 'Text';
            %   text.BackgroundColor = [200 100 10];
            %   text.ForegroundColor = [100 10 200];
            
              data{1,1} = button;
              data{1,2} = check;
              data{1,3} = combo;
              data{2,1} = hyperlink;
              data{2,2} = edit;
              data{2,3} = text;
              
              table.Type = 'table';
              table.Tag = 'my_table';
              table.WidgetId = 'my_table_Id';
              table.Size = [2 3];
              table.RowHeader = {'Row 1', 'Row 2'};
              table.ColHeader = {'Col 1', 'Col 2', 'Col 3'};
              table.Editable = true;
              table.Data = data;
              table.RowSpan = [6 6];
              table.ColSpan = [1 4];
            %   table.Enabled = false;
              %table.ColumnCharacterWidth = []; %g528277
              %table.RowHeaderWidth  = []; %g528277
              table.BackgroundColor = [200 100 50]; % Set background  for g9564365
              table.ForegroundColor = [100 200 50]; % Set foreground color  for g9564365
              table.SelectedRow = 2;
              table.ToolTip = 'table widget tooltip';
              table.ValueChangedCallback = @onValueChanged;
              table.ItemClickedCallback = @onItemClicked;
              table.ItemDoubleClickedCallback = @onItemDoubleClicked;
              table.SelectionChangedCallback  = @onSelectionChanged;
            %   table.ReadOnlyColumns = [0 1 2];
            %   table.ReadOnlyRows = [0];
            
              autoEdit.Type = 'edit';
              autoEdit.Name = 'Auto complete edit box';
              autoEdit.AutoCompleteViewColumn = {'name', 'type'};
              autoEdit.AutoCompleteViewData = {'item 1', 'item 2', 'item 3', 'a', 'b', 'c'};
              
              autoEditArea.Type = 'editarea';
              autoEditArea.Name = 'Auto complete editarea: ';
              autoEditArea.Tag = 'aeditarea';
              autoEditArea.AutoCompleteViewData = {'item 1', 'item 2', 'item 3', 'a', 'b', 'c'};
              autoEditArea.AutoCompleteTrigger = '%';
              
              togglePanel.Name       = 'Click to show additional parameters';
              togglePanel.Type       = 'togglepanel';
              togglePanel.Items      = {autoEdit, autoEditArea};
              togglePanel.Tag        = 'my_togglepanel_tag';
              togglePanel.WidgetId   = 'my_togglepanel_widgetid';
              togglePanel.Expand = true;
              togglePanel.ExpandCallback = @onExpandChanged;
              togglePanel.RowSpan = [7 7];
              togglePanel.ColSpan = [1 4];
            
              %%%%%%%%%%%%%%%%%%%%%%%
              % Main dialog
              %%%%%%%%%%%%%%%%%%%%%%%
              dlgstruct.DialogTitle = 'Slider, Dial, SpinBox and SplitButton';
              dlgstruct.Items = {dialGroup, spinnerGroup, sliderGroup, split, split2, toggle, table, editor, togglePanel};
              dlgstruct.MinMaxButtons = true;
              dlgstruct.Geometry = [200, 200, 400, 500];
              dlgstruct.LayoutGrid  = [7 4];
              dlgstruct.RowStretch  = [0 0 0 0 0 1 0];
              dlgstruct.ColStretch  = [0 0 0 1];
              %   dlgstruct.DialogMode = 'normal';
              %   dlgstruct.Transient = true;
              %   dlgstruct.DialogStyle = 'resizableframeless';
              %   dlgstruct.StandaloneButtonSet = {''};
        end

        function [success,msg] = sliderCallback(h, hDlg, tag) 
            success = true;
            msg = '';
            hDlg.getWidgetValue(tag)
            disp(['sliderCallback is called from ', tag, '!']);
        end

        function [success,msg] = buttonClickedCallback(h, hDlg, tag) 
            success = true;
            msg = '';
            disp(['buttonClickedCallback is called from ', tag, '!']);
        end
    end
end

function actionCallback(d, buttontag, actiontag)
    disp('in actionCallback')
    disp(sprintf('splitbutton tag: ''%s'', action tag: ''%s''', buttontag, actiontag));
end

function onValueChanged(d, r, c, val)
    disp('in onValueChanged')
    if isstr(val) 
      disp(sprintf('item at (%d, %d) changed to ''%s''', r,c,val));
    else
      disp(sprintf('item at (%d, %d) changed to %d', r,c,val));
    end
end

function onItemClicked(d, r,c, name)
    disp('in onItemClicked')
    disp(sprintf('item ''%s'' at (%d, %d) is clicked.', name, r, c));
end

function onItemDoubleClicked(d, r,c, name)
    disp('in onItemDoubleClicked')
    disp(sprintf('item ''%s'' at (%d, %d) is double clicked.', name, r, c));
end

function onSelectionChanged(d, tag)
    disp('in onSelectionChanged')
    disp(sprintf('Table widget ''%s'' selection is changed.', tag));
end

function onExpandChanged(d, tag, state)
    disp('in onExpandChanged')
    if state
        disp(sprintf('Table togglepanel ''%s'' is expanded. ', tag));  
    else
        disp(sprintf('Table togglepanel ''%s'' is collapsed. ', tag));  
    end
end

function SpinboxTextValidate(dlg, tag, numToEval, textToEval)
    try    
        value = evalin('base', textToEval);
        if isnumeric(value)
            dlg.setWidgetValue(tag, value);
            disp(sprintf('The Spinbox value is changed to ''%d'' . ', value));
        else
            disp(sprintf('Value is not numeric! The Spinbox value is not set. '));  
        end
    catch E
        success = false;
        msg = E.message;
        disp(sprintf('The Spinbox value is not set. '));  
    end
end

function SliderReleasedCB(dlg, tag, value)
    disp(sprintf('SliderReleasedCB called for tag ''%s'' with value ''%d'' . ', tag, value));
end
