classdef ImshowDisplayPreferences < handle
% Class that handles the IMSHOW Display Preferences for Javascript Desktop

% Copyright 2022-2023 The MathWorks, Inc.
    properties(Access = public)
        UIFigure;
    end

    properties(Access=private)
        % UI Controls

        % Axes Visibility Section
        ChkBoxAxesVisible

        % Initial Magnification Section
        RadioFit
        RadioPrefPct
        EditPrefPct
        LabelPrefPct

        % Border Style Section
        RadioLoose
        RadioTight
    end

    properties(Access=private, Constant)
        Width = 450;
        Margin = 10;
        TextElemsHeight = 20;
        TextElemsWidth = 150;

        VertRadioButtonSpacing = 5;
        ButtonGrpHeight = 80;
        PrefPctEditWidth = 50;
    end

    % Construction
    methods(Access=public)
        function obj = ImshowDisplayPreferences()
            createPanel(obj);
        end

        function delete(obj)
            delete(obj.UIFigure);
        end
    end

    % Public interface
    methods(Access=public)
        function result = commit(obj)
            % Commit the changes to the stored IMSHOW settings

            try
                s = settings;
                imshowPrefs = s.matlab.imshow;
                imshowPrefs.ShowAxes.PersonalValue = obj.ChkBoxAxesVisible.Value;
                
                if obj.RadioLoose.Value
                    imshowPrefs.BorderStyle.PersonalValue = 'loose';
                else
                    imshowPrefs.BorderStyle.PersonalValue = 'tight';
                end
                
                if obj.RadioFit.Value
                    imshowPrefs.InitialMagnificationStyle.PersonalValue = 'fit';
                else
                    imshowPrefs.InitialMagnificationStyle.PersonalValue = 'numeric';
                    imshowPrefs.InitialMagnification.PersonalValue = obj.EditPrefPct.Value;
                end
                result = true;
            catch ME
                result = false;
            end
        end
    end

    methods(Access=private)
        function createPanel(obj)
            % Create the Panel. The layout of the panel is as below:
            % CHKBOX - Display Axes
            % RADIO BUTTON GRP - Border Style
            %   Loose
            %   Tight
            % RADIO BUTTON GRP - Initial Mag
            %   Fit to Window
            %   Pref Percentage: TEXTBOX with value

            obj.UIFigure = uifigure;
            obj.UIFigure.AutoResizeChildren = "off";
            obj.UIFigure.Scrollable = "on";

            % Create a 1x1 Grid Layout to place the main panel into which
            % all the components will be added. This is to make handling of
            % resizing easy.
            figUG = uigridlayout(obj.UIFigure, [1 1]);
            figUG.Scrollable = "on";
            figUG.RowHeight = {'1x'};
            figUG.ColumnWidth = {'1x'};

            mainPanel = uipanel( figUG, ...
                                 BorderType="none", ...
                                 Title=string(message('MATLAB:images:preferencesIMSHOW:imshowDisplay')) );
            mainPanel.AutoResizeChildren = "off";
            mainPanel.Scrollable = "off";
            
            mainUG = uigridlayout(mainPanel, [3 1]);
            mainUG.Scrollable = "on";
            mainUG.RowHeight = {obj.TextElemsHeight obj.ButtonGrpHeight obj.ButtonGrpHeight};
            mainUG.ColumnWidth = {obj.Width};

            % Show Axes Check Box
            obj.ChkBoxAxesVisible = uicheckbox( mainUG, ...
                                        Text=string(message('MATLAB:images:preferencesIMSHOW:axesVisible')), ...
                                        Tag="ChkBoxAxesVisible" );
            obj.ChkBoxAxesVisible.Layout.Row = 1;
            obj.ChkBoxAxesVisible.Layout.Column = 1;

            % Border Style Button Group
            borderStyleBtnGrp = uibuttongroup( mainUG, ...
                                    Title=string(message('MATLAB:images:preferencesIMSHOW:border')), ...
                                    FontWeight="bold", ...
                                    Tag="BorderStyleBtnGrp" );
            borderStyleBtnGrp.AutoResizeChildren = "off";
            borderStyleBtnGrp.Layout.Row = 2;
            borderStyleBtnGrp.Layout.Column = 1;
            
            % Position the buttons in this button group bottom up
            radioLoosePos = [obj.Margin obj.Margin obj.TextElemsWidth obj.TextElemsHeight];

            radioTightPos = [ radioLoosePos(1) ...
                              radioLoosePos(2)+radioLoosePos(4)+obj.VertRadioButtonSpacing ...
                              radioLoosePos(3) obj.TextElemsHeight ];

            obj.RadioTight = uiradiobutton( borderStyleBtnGrp, ...
                                Text=string(message('MATLAB:images:preferencesIMSHOW:tight')), ...
                                Position=radioTightPos,...
                                Tag="RadioTight" );

            obj.RadioLoose = uiradiobutton( borderStyleBtnGrp, ...
                                Text=string(message('MATLAB:images:preferencesIMSHOW:loose')), ...
                                Position=radioLoosePos, ...
                                Tag="RadioLoose" );
            
            % Initial Magnification Button Group
            initMagBtnGrp = uibuttongroup( mainUG, ...
                                Title=string(message('MATLAB:images:preferencesIMSHOW:initMag')), ...
                                FontWeight="bold", ...
                                Tag="InitMagBtnGrp" );
            initMagBtnGrp.AutoResizeChildren = "off";
            initMagBtnGrp.Layout.Row = 3;
            initMagBtnGrp.Layout.Column = 1;
            initMagBtnGrp.SizeChangedFcn = @obj.initMagBtnGrpSizeChgFcn;
            initMagBtnGrp.SelectionChangedFcn = @(src,evt) obj.initMagGroupChanged(src, evt);

            % Position the buttons in this group bottom up
            radioPrefPctPos = [obj.Margin obj.Margin obj.TextElemsWidth obj.TextElemsHeight];

            editPrefPctPos = [ radioPrefPctPos(1)+radioPrefPctPos(3)+obj.Margin ...
                               radioPrefPctPos(2) obj.PrefPctEditWidth obj.TextElemsHeight ];

            bgpos = initMagBtnGrp.Position;
            labelWidth = bgpos(3) - (editPrefPctPos(1)+editPrefPctPos(3)+obj.Margin);
            labelPos = [ editPrefPctPos(1)+editPrefPctPos(3)+obj.Margin ...
                         editPrefPctPos(2) labelWidth ...
                         obj.TextElemsHeight ];

            radioFitPos = [ radioPrefPctPos(1) ...
                            radioPrefPctPos(2)+radioPrefPctPos(4)+obj.VertRadioButtonSpacing ...
                            radioPrefPctPos(3) obj.TextElemsHeight ];

            obj.RadioFit = uiradiobutton( initMagBtnGrp, ...
                                Text=string(message('MATLAB:images:preferencesIMSHOW:fit')), ...
                                Position=radioFitPos, ...
                                Tag="RadioFit" );

            obj.RadioPrefPct = uiradiobutton( initMagBtnGrp, ...
                                    Text=string(message('MATLAB:images:preferencesIMSHOW:prefPercentage')), ...
                                    Position=radioPrefPctPos, ...
                                    Tag="RadioPrefPct" );
            
            % Position the edit field
            obj.EditPrefPct = uieditfield( initMagBtnGrp, "numeric", ...
                                            Position=editPrefPctPos, ...
                                            Tag="EditPrefPct" );
            obj.EditPrefPct.ValueDisplayFormat = '%3.0f%%';
            obj.EditPrefPct.Value = 100;
            obj.EditPrefPct.Limits = [0 inf];
             
            % Position the label
            obj.LabelPrefPct = uilabel( initMagBtnGrp, ...
                                    Text=string(message('MATLAB:images:preferencesIMSHOW:orLess')), ...
                                    Position=labelPos, ...
                                    Tag = "PrefPctLabel" );
            setViewValues(obj);
        end

        function setViewValues(obj)
            % Set the Values on the Preferences UI using stored values in
            % the settings. This is done when loading the preference panel
            % UI

            s = settings;
            imshowPrefs = s.matlab.imshow;

            obj.ChkBoxAxesVisible.Value = imshowPrefs.ShowAxes.ActiveValue;
                    
            switch (imshowPrefs.BorderStyle.ActiveValue)
                case 'loose'
                    obj.RadioLoose.Value = true;
                case 'tight'
                    obj.RadioTight.Value = true;
                otherwise
                    assert(false)
            end
            
            switch (imshowPrefs.InitialMagnificationStyle.ActiveValue)
                case 'fit'
                    obj.RadioFit.Value = true;
                    obj.EditPrefPct.Enable = false;
                case 'numeric'
                    obj.RadioPrefPct.Value = true;
                    obj.EditPrefPct.Value = imshowPrefs.InitialMagnification.ActiveValue;
                    obj.EditPrefPct.Enable = true;
            end
        end
    
        function initMagGroupChanged(obj, ~, evt)
            obj.EditPrefPct.Enable = evt.NewValue.Tag == "RadioPrefPct";
        end

        function initMagBtnGrpSizeChgFcn(obj, src, ~)
        % Size changed function for the Initial Mag Button Group. This is
        % needed to accurately position the uilabel that follows the edit
        % field
        
            bgpos = src.Position; 
            editPrefPctPos = obj.EditPrefPct.Position;
            labelWidth = bgpos(3) - (editPrefPctPos(1)+editPrefPctPos(3)+obj.Margin);
            labelPos = [ editPrefPctPos(1)+editPrefPctPos(3)+obj.Margin ...
                         editPrefPctPos(2) labelWidth ...
                         obj.TextElemsHeight ];
            obj.LabelPrefPct.Position = labelPos;
        end
    end
end
