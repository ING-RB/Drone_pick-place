classdef JavaRunTimeEnvironmentPreferencePanel < handle
    %MATFILEPREFERENCEPANEL The preference panel for MATLAB save format
    %   The class describing the MATLAB General MAT-Files Preferences pane
    %   in Preferences window.

%   Copyright 2020-2025 The MathWorks, Inc.

    properties (Access = public)
        UIFigure;
        TopGrid;
        UISlider;
        UISpinner;
        BYOJGroupGrid;
        BYOJDescriptionLabel;
        PathforJREEditField;
        GetFileButton;
        SystemversionofJREButton;
        DefaultversionofJREButton;
        CustomPathButton;
        PathforJREEditFieldLabel
    end


    methods (Access = private)

        function SliderValueChanged(obj,hslider,event)
          %  disp "hello";
            obj.UISlider.Value = round(obj.UISlider.Value);
            obj.UISpinner.Value = obj.UISlider.Value;
        end

        function SpinnerValueChanged(obj,hspinner,event)
          %  disp "hello";
            obj.UISpinner.Value = round(obj.UISpinner.Value);
            obj.UISlider.Value = obj.UISpinner.Value;
        end

        function ButtonGroupSelectionChanged(obj,hGroupGrid, event)
            switch obj.BYOJGroupGrid.SelectedObject.Tag
                case 'System'
                    obj.PathforJREEditFieldLabel.Enable = 'off';
                    obj.PathforJREEditField.Enable = 'off';
                    obj.GetFileButton.Enable = 'off';
                case 'Default'
                    obj.PathforJREEditFieldLabel.Enable = 'off';
                    obj.PathforJREEditField.Enable = 'off';
                    obj.GetFileButton.Enable = 'off';
                case 'Custom'
                    obj.PathforJREEditFieldLabel.Enable = 'on';
                    obj.PathforJREEditField.Enable = 'on';
                    obj.GetFileButton.Enable = 'on';
                otherwise
            end
        end

        function GetJRELocationFilePath(obj,hbutton,event)
            pathname = uigetdir();
            if isequal(pathname,0)
               %TODO Error Handling
            else
               obj.PathforJREEditField.Value = pathname;
            end
        end

    end

    methods (Access = public)

        % Constructor
        function obj = JavaRunTimeEnvironmentPreferencePanel()
            %MATFILEPREFERENCEPANEL Construct an instance of this class
            % Create uiFigure
            obj.UIFigure = uifigure;

            s = settings;


            % Create a Top Grid
            TopGrid = uigridlayout(obj.UIFigure);
            TopGrid.RowHeight = {'1x','1x'};
            TopGrid.ColumnWidth = {'1x'};

            % Create Panel_1 For HeapMemory
            HeapMemoryPreferencePanel = uipanel(TopGrid);
            HeapMemoryPreferencePanel.Layout.Row = 1;
            HeapMemoryPreferencePanel.Layout.Column = 1;


            % Create Panel_2 For BYOJ
            BYOJPreferencePanel = uipanel(TopGrid);
            BYOJPreferencePanel.Layout.Row = 2;
            BYOJPreferencePanel.Layout.Column = 1;


            % BYOJ Panel
            % Create grid

            JREPath = s.matlab.external.interfaces.java.(computer('arch')).JrePath;

            BYOJTopGrid = uigridlayout(BYOJPreferencePanel);
            BYOJTopGrid.RowHeight = {'fit','1x'};
            BYOJTopGrid.ColumnWidth = {'1x'};

            BYOJTitleLabel = uilabel(BYOJTopGrid);
            BYOJTitleLabel.Text = getTextString('MATLAB:Java:BYOJTitle');

            BYOJpanelGrid = uigridlayout(BYOJTopGrid);
            BYOJpanelGrid.RowHeight = {'1x'};
            BYOJpanelGrid.ColumnWidth = {'1x'};

            % Create TextLabel
            obj.BYOJGroupGrid = uibuttongroup(BYOJpanelGrid,...
                                                'SelectionChangedFcn',@obj.ButtonGroupSelectionChanged);

            obj.BYOJDescriptionLabel = uilabel(obj.BYOJGroupGrid,...
                                                 'Position',[10 160 550 20]);

            obj.BYOJDescriptionLabel.Text = getTextString('MATLAB:Java:BYOJDescription');

            % Create DefaultversionofJREButton
            obj.DefaultversionofJREButton = uiradiobutton(obj.BYOJGroupGrid,...
                                                            'Position',[10 114 400 30]);
            obj.DefaultversionofJREButton.Tag = 'Default';
            obj.DefaultversionofJREButton.Text = {getTextString('MATLAB:Java:DefaultVersion');getTextString('MATLAB:Java:DefaultVersionDescription')};

            % Create SystemversionofJREButton
            obj.SystemversionofJREButton = uiradiobutton(obj.BYOJGroupGrid,...
                                                            'Position',[10 77 400 30]);
            obj.SystemversionofJREButton.Tag = 'System';
            obj.SystemversionofJREButton.Text = {getTextString('MATLAB:Java:SystemVersion');getTextString('MATLAB:Java:SystemVersionDescription')};

            % Create CustomPathButton
            obj.CustomPathButton = uiradiobutton(obj.BYOJGroupGrid,...
                                                            'Position',[10 40 400 30]);
            obj.CustomPathButton.Tag='Custom';
            obj.CustomPathButton.Text = {getTextString('MATLAB:Java:CustomPath');getTextString('MATLAB:Java:CustomPathDescription')};

            if(JREPath.ActiveValue == "system")
                obj.SystemversionofJREButton.Value = true;
                obj.DefaultversionofJREButton.Value = false;
                obj.CustomPathButton.Value = false;
            elseif( (JREPath.ActiveValue == "default") || (JREPath.ActiveValue == "factory"))
                obj.DefaultversionofJREButton.Value = true;
                obj.SystemversionofJREButton.Value = false;
                obj.CustomPathButton.Value = false;
            else
                obj.CustomPathButton.Value = true;
                obj.DefaultversionofJREButton.Value = false;
                obj.SystemversionofJREButton.Value = false;
            end

            % Create PathforJREEditFieldLabel
            obj.PathforJREEditFieldLabel = uilabel(obj.BYOJGroupGrid);
            obj.PathforJREEditFieldLabel.HorizontalAlignment = 'right';
            obj.PathforJREEditFieldLabel.Position = [30 15 100 20];
            obj.PathforJREEditFieldLabel.Text = getTextString('MATLAB:Java:CustomPathForJRE');
            obj.PathforJREEditFieldLabel.Enable = 'off';
            obj.PathforJREEditField = uieditfield(obj.BYOJGroupGrid);
            obj.PathforJREEditField.Position = [150 15 150 20];
            obj.PathforJREEditField.Enable = 'off';
            obj.GetFileButton = uibutton(obj.BYOJGroupGrid,'push',...
                "ButtonPushedFcn",@obj.GetJRELocationFilePath);
            obj.GetFileButton.Position = [310 15 29 20];
            obj.GetFileButton.Text = '...';

            switch obj.BYOJGroupGrid.SelectedObject.Tag
               case 'System'
                    obj.PathforJREEditFieldLabel.Enable = 'off';
                    obj.PathforJREEditField.Enable = 'off';
                    obj.GetFileButton.Enable = 'off';
               case 'Default'
                    obj.PathforJREEditFieldLabel.Enable = 'off';
                    obj.PathforJREEditField.Enable = 'off';
                    obj.GetFileButton.Enable = 'off';
               case 'Custom'
                    obj.PathforJREEditFieldLabel.Enable = 'on';
                    obj.PathforJREEditField.Enable = 'on';
                    obj.GetFileButton.Enable = 'on';
                    obj.PathforJREEditField.Value = JREPath.ActiveValue;
               otherwise
            end



             % Create grid For Heap Memory PrefrencePanel
            HeapMemoryTopGrid = uigridlayout(HeapMemoryPreferencePanel);
            HeapMemoryTopGrid.RowHeight = {'fit','fit'};
            HeapMemoryTopGrid.ColumnWidth = {'fit'};

            heapSize = s.matlab.external.interfaces.java.HeapSize;

            HeapMemoryTitleLabel = uilabel(HeapMemoryTopGrid);
            HeapMemoryTitleLabel.Text = getTextString('MATLAB:Java:HeapSizeTitle');

            % Create buttons
            GroupGrid = uibuttongroup(HeapMemoryTopGrid);

            panelGrid = uigridlayout(GroupGrid);
            panelGrid.RowHeight = {'fit','fit','fit'};
            panelGrid.ColumnWidth = {'fit'};

            section1Grid = uigridlayout(panelGrid);
            section1Grid.RowHeight = {'fit'};
            section1Grid.ColumnWidth = {500};
          % Create TextLabel
            TextLabel = uilabel(section1Grid);
            TextLabel.Layout.Row = 1;
            TextLabel.Layout.Column = 1;
            TextLabel.WordWrap = 1;
            TextLabel.Text = {getTextString('MATLAB:Java:HeapSizeDescription')};

            section2Grid = uigridlayout(panelGrid);
            section2Grid.RowHeight = {'fit'};
            section2Grid.ColumnWidth = {350,'fit','fit'};
          % Create slider
            obj.UISlider = uislider (section2Grid,...
                'ValueChangedFcn',@obj.SliderValueChanged);
            obj.UISlider.Limits = [128 8192];
            obj.UISlider.MajorTicks = [128 4160 8192];
            obj.UISlider.MajorTickLabels = {'128', '4160', '8192'};
            obj.UISlider.MinorTicks = [128 4160 8192];
            obj.UISlider.Layout.Row = 1;
            obj.UISlider.Layout.Column = 1;
            obj.UISlider.Value = heapSize.ActiveValue;
          % Create MBSpinner
            obj.UISpinner = uispinner(section2Grid,...
                'ValueChangedFcn',@obj.SpinnerValueChanged);
            obj.UISpinner.Limits = [128 8192];
            obj.UISpinner.Layout.Row = 1;
            obj.UISpinner.Layout.Column = 2;
            obj.UISpinner.Value = obj.UISlider.Value;
          % Create MBSpinnerLabel
            UISpinnerLabel = uilabel(section2Grid);
            UISpinnerLabel.HorizontalAlignment = 'right';
            UISpinnerLabel.VerticalAlignment = 'top';
            UISpinnerLabel.Layout.Row = 1;
            UISpinnerLabel.Layout.Column = 3;
            UISpinnerLabel.Text = 'MB';


            section3Grid = uigridlayout(panelGrid);
            section3Grid.RowHeight = {'fit'};
            section3Grid.ColumnWidth = {50,'fit'};
          % Create NoteLabel
            NoteLabel = uilabel(section3Grid);
            NoteLabel.Layout.Row = 1;
            NoteLabel.Layout.Column = 2;

            NoteLabel.Text = getTextString('MATLAB:Java:HeapSizeNotelabel',heapSize.ActiveValue,heapSize.FactoryValue);
        end

        function result = commit(obj)
             try
                  % Save the preferences
                  s = settings;
                  JREPath = s.matlab.external.interfaces.java.(computer('arch')).JrePath;
                  s.matlab.external.interfaces.java.HeapSize.PersonalValue = obj.UISlider.Value;
                  switch obj.BYOJGroupGrid.SelectedObject.Tag
                      case 'System'
                            JREPath.PersonalValue = 'system';
                      case 'Default'
                            JREPath.PersonalValue = 'default';
                      case 'Custom'
                            if isempty(obj.PathforJREEditField.Value)
                                errordlg(getTextString('MATLAB:Java:JRECannotBeEmpty'),'Input Error');
                                result = false;
                                return;
                            else
                                JREPath.PersonalValue = obj.PathforJREEditField.Value;
                            end
                      otherwise

                  end
                  result = true;
             catch ME
                  result = false;
             end


        end

        function delete(obj)
            delete(obj.UIFigure);
        end
  end

end

function str = getTextString(id, varargin)
    % Reads strings from the resource bundle
    str = getString(message(id, varargin{:}));
end
