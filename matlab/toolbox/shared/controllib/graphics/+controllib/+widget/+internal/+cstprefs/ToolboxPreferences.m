classdef (CaseInsensitiveProperties=true) ToolboxPreferences < handle ...
        & matlab.mixin.Copyable ...
        & matlab.mixin.SetGet
    %% ToolboxPreferences - Singleton class that provides toolbox preference options.
    %
    %    ToolboxPreferences properties:
    %       FrequencyUnits - Property is of type 'string'
    %       FrequencyScale - Property is of type 'string'
    %       MagnitudeUnits - Property is of type 'string'
    %       MagnitudeScale - Property is of type 'string'
    %       PhaseUnits - Property is of type 'string'
    %       TimeUnits - Property is of type 'string'
    %       Grid - Property is of type 'string'
    %       TitleFontSize - Property is of type 'MATLAB array'
    %       TitleFontWeight - Property is of type 'string'
    %       TitleFontAngle - Property is of type 'string'
    %       XYLabelsFontSize - Property is of type 'MATLAB array'
    %       XYLabelsFontWeight - Property is of type 'string'
    %       XYLabelsFontAngle - Property is of type 'string'
    %       AxesFontSize - Property is of type 'MATLAB array'
    %       AxesFontWeight - Property is of type 'string'
    %       AxesFontAngle - Property is of type 'string'
    %       IOLabelsFontSize - Property is of type 'MATLAB array'
    %       IOLabelsFontWeight - Property is of type 'string'
    %       IOLabelsFontAngle - Property is of type 'string'
    %       AxesForegroundColor - Property is of type 'MATLAB array'
    %       GridColor - Property is of type 'MATLAB array'
    %       SettlingTimeThreshold - Property is of type 'MATLAB array'
    %       RiseTimeLimits - Property is of type 'MATLAB array'
    %       UnwrapPhase - Property is of type 'string'
    %       PhaseWrappingBranch - Property is of type 'MATLAB array'
    %       ComparePhase - Property is of type 'MATLAB array'
    %       MinGainLimit - Property is of type 'MATLAB array'
    %       PIDTunerPreferences - Property is of type 'MATLAB array'
    %       CompensatorFormat - Property is of type 'string'
    %       ShowSystemPZ - Property is of type 'string'
    %       SISOToolStyle - Property is of type 'MATLAB array'
    %       UIFontSize - Property is of type 'MATLAB array'
    %       Version - Property is of type 'MATLAB array'
    %       StartUpMsgBox - Property is of type 'MATLAB array'
    %
    %    ToolboxPreferences methods:
    %       edit -  Opens GUI for editing toolbox preferences
    %       load -  Loads toolbox preferences from a file
    %       save -  Saves current toolbox preferences to a file
    %
    %    Example:
    %        %% Create toolbox preferences.
    %        prefs = controllib.widget.internal.cstprefs.ToolboxPreferences.getInstance;
    %
    %        %% Edit toolbox preferences using UI.
    %        edit(prefs)
    %
    %        %% Update and save toolbox preferences to settings
    %        prefs.Grid = 'on';
    %        save(prefs)
    %
    %        %% Load toolbox preferences from settings.
    %        load(prefs)
    %
    %    See also
    %        controllib.widget.internal.cstprefs.ToolboxPreferenceDialog
    %        controllib.widget.internal.cstprefs.ToolboxPreferencePanel

    %  Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties
        FrequencyUnits
        FrequencyScale
        MagnitudeUnits
        PhaseUnits
        TimeUnits
        Grid                        matlab.lang.OnOffSwitchState
        TitleFontSize
        TitleFontWeight
        TitleFontAngle
        XYLabelsFontSize
        XYLabelsFontWeight
        XYLabelsFontAngle
        AxesFontSize
        AxesFontWeight
        AxesFontAngle
        IOLabelsFontSize
        IOLabelsFontWeight
        IOLabelsFontAngle
        AxesForegroundColor
        GridColor
        SettlingTimeThreshold
        RiseTimeLimits
        UnwrapPhase
        ComparePhase
        PIDTunerPreferences
        CompensatorFormat
        ShowSystemPZ
        SISOToolStyle
        UIFontSize
        Version
        StartUpMsgBox
    end

    properties(Dependent)
        MinGainLimit
        MagnitudeScale
        PhaseWrappingBranch

        TitleFontSizeFactoryValue
        TitleFontWeightFactoryValue
        XYLabelsFontSizeFactoryValue
        IOLabelsFontSizeFactoryValue
        AxesFontSizeFactoryValue
    end

    properties(Hidden,Dependent,SetAccess=private)
        AxesForegroundColorFactoryValue
        AxesForegroundColorMode
        GridColorFactoryValue
        GridColorMode
    end

    properties(Hidden,GetAccess=public,SetAccess=private)
        GraphicsSettings = settings().controlshared.graphics
    end

    properties(Access=private)
        Dialog
        LocalMinGainLimit
        LocalMagnitudeScale
        LocalPhaseWrappingBranch
        
        VersionFactoryValue = 4;
    end

    %% Constructor
    methods(Access=private)
        function this = ToolboxPreferences
            %% Constructs a toolbox preferences object.

            % Reset to default values.
            this.reset()

            % Load default user preference file (if it exists)
            this.load()
        end

    end

    %% Destructor
    methods
        function delete(this)
            %% Release resources.

            if ~isempty(this.Dialog) && isvalid(this.Dialog)
                delete(this.Dialog)
                this.Dialog = [];
            end

            clear this
        end
    end

    %% Set/Get
    methods
        function set.MagnitudeUnits(this,currUnit)
            if isequal(this.MagnitudeUnits,currUnit)
                return
            else
                preVal = this.MagnitudeUnits;
                this.MagnitudeUnits = char(currUnit);
                if isempty(preVal)
                    return
                end
            end
            updateMagDependents(this)
        end
        
        function set.MinGainLimit(this,value)
            this.LocalMinGainLimit = value;
        end

        function value = get.MinGainLimit(this)
            value = this.LocalMinGainLimit;
        end

        function set.MagnitudeScale(this,value)
            this.LocalMagnitudeScale = value;
        end

        function value = get.MagnitudeScale(this)
            value = this.LocalMagnitudeScale;
        end

        function set.PhaseUnits(this,currUnit)
            if isequal(this.PhaseUnits,currUnit)
                return
            else
                preVal = this.PhaseUnits;
                this.PhaseUnits = char(currUnit);
                if isempty(preVal)
                    return
                end
            end
            updatePhaseDependents(this)
        end

        function set.PhaseWrappingBranch(this,value)
            this.LocalPhaseWrappingBranch = value;
        end

        function value = get.PhaseWrappingBranch(this)
            value = this.LocalPhaseWrappingBranch;
        end

        function updatePhaseDependents(this)
            preValue = this.LocalPhaseWrappingBranch;
            currUnit = this.PhaseUnits;
            preUnit = char(setdiff(["deg" "rad"],currUnit));
            this.LocalPhaseWrappingBranch = unitconv(preValue,preUnit,currUnit);
        end

        function AxesForegroundColorMode = get.AxesForegroundColorMode(this)
            if isequal(this.AxesForegroundColor,...
                    this.GraphicsSettings.style.AxesForegroundColor.FactoryValue)
                AxesForegroundColorMode = "auto";
            else
                AxesForegroundColorMode = "manual";
            end
        end

        function AxesForegroundColorFactoryValue = get.AxesForegroundColorFactoryValue(this)
            AxesForegroundColorFactoryValue = this.GraphicsSettings.style.AxesForegroundColor.FactoryValue;
        end

        function GridColorMode = get.GridColorMode(this)
            if isequal(this.GridColor,this.GraphicsSettings.style.GridColor.FactoryValue)
                GridColorMode = "auto";
            else
                GridColorMode = "manual";
            end
        end

        function GridColorFactoryValue = get.GridColorFactoryValue(this)
            GridColorFactoryValue = this.GraphicsSettings.style.GridColor.FactoryValue;
        end

        function titleFontSizeFactoryValue = get.TitleFontSizeFactoryValue(this)
            titleFontSizeFactoryValue = ...
                get(0,'DefaultAxesFontSize') * get(0,'DefaultAxesLabelFontSizeMultiplier');
        end

        function titleFontWeightFactoryValue = get.TitleFontWeightFactoryValue(this)
            titleFontWeightFactoryValue = get(0,'DefaultAxesTitleFontWeight');
        end

        function xylabelsFontSizeFactoryValue = get.XYLabelsFontSizeFactoryValue(this)
            xylabelsFontSizeFactoryValue = ...
                get(0,'DefaultAxesFontSize') * get(0,'DefaultAxesLabelFontSizeMultiplier');
        end

        function iolabelsFontSizeFactoryValue = get.IOLabelsFontSizeFactoryValue(this)
            iolabelsFontSizeFactoryValue = get(0,'DefaultAxesFontSize');
        end

        function axesFontSizeFactoryValue = get.AxesFontSizeFactoryValue(this)
            axesFontSizeFactoryValue = get(0,'DefaultAxesFontSize');
        end
    end

    %% Public Methods
    methods
        function varargout = edit(this)
            % Open GUI for editing Toolbox Preferences.

            if isempty(this) || ~isvalid(this)
                error(message( 'MATLAB:class:InvalidHandle'))
            end

            import controllib.widget.internal.cstprefs.ToolboxPreferenceDialog
            if isempty(this.Dialog) || ~isvalid(this.Dialog)
                this.Dialog = ToolboxPreferenceDialog(this);
            end
            this.Dialog.show()

            if nargout > 0
                varargout{1} = this.Dialog;
            end
        end

        function reset(this)
            % Reset to default factory values.

            if isempty(this) || ~isvalid(this)
                error(message( 'MATLAB:class:InvalidHandle'))
            end

            %---Define properties
            restoreUnitPreferences(this)
            restoreStylePreferences(this)
            restoreResponsePreferences(this)
            restoreCSDPreferences(this)
            restorePIDTunerPreferences(this);
            
            this.GraphicsSettings.ui.UIFontSize.PersonalValue = get(0,'DefaultUIControlFontSize');
            this.UIFontSize = get(0,'DefaultUIControlFontSize');
            this.Version = this.VersionFactoryValue;
        end

        function restoreUnitPreferences(this)
            % units
            units = this.GraphicsSettings.units;
            this.TimeUnits = units.TimeUnits.FactoryValue;
            this.FrequencyUnits = units.FrequencyUnits.FactoryValue;
            this.FrequencyScale = units.FrequencyScale.FactoryValue;
            this.MagnitudeUnits = units.MagnitudeUnits.FactoryValue;
            this.MagnitudeScale = units.MagnitudeScale.FactoryValue;
            this.PhaseUnits = units.PhaseUnits.FactoryValue;
        end

        function restoreStylePreferences(this)
            style = this.GraphicsSettings.style;
            
            % grid
            this.Grid = style.Grid.FactoryValue;
            this.GridColor = style.GridColor.FactoryValue;
            % title font
            localSetDefault('TitleFontSize',style.TitleFontSize)
            localSetDefault('TitleFontWeight',style.TitleFontWeight);
            this.TitleFontAngle = style.TitleFontAngle.FactoryValue;
            % xylabel font
            localSetDefault('XYLabelsFontSize',style.XYLabelsFontSize);
            this.XYLabelsFontAngle = style.XYLabelsFontAngle.FactoryValue;
            this.XYLabelsFontWeight = style.XYLabelsFontWeight.FactoryValue;
            % iolabel font
            localSetDefault('IOLabelsFontSize',style.IOLabelsFontSize);
            this.IOLabelsFontWeight = style.IOLabelsFontWeight.FactoryValue;
            this.IOLabelsFontAngle = style.IOLabelsFontAngle.FactoryValue;
            % axes font and color
            localSetDefault('AxesFontSize',style.AxesFontSize);
            this.AxesFontWeight = style.AxesFontWeight.FactoryValue;
            this.AxesFontAngle = style.AxesFontAngle.FactoryValue;
            this.AxesForegroundColor = style.AxesForegroundColor.FactoryValue;
            
            % Local function to set defaults
            function localSetDefault(propertyName,s)
                defaultValue = this.([propertyName,'FactoryValue']);
                if ~hasPersonalValue(s) || isequal(s.PersonalValue,s.FactoryValue)
                    s.PersonalValue = defaultValue;
                end
                this.(propertyName) = defaultValue;
            end
        end
        
        function restoreResponsePreferences(this)
            % response
            response = this.GraphicsSettings.response;
            this.SettlingTimeThreshold = response.SettlingTimeThreshold.FactoryValue;
            this.RiseTimeLimits = response.RiseTimeLimits.FactoryValue;
            if strcmp(response.PhaseWrappingEnabled.FactoryValue,'off')
                this.UnwrapPhase = 'on';
            else
                this.UnwrapPhase = 'off';
            end
            this.PhaseWrappingBranch = response.PhaseWrappingBranch.FactoryValue;
            this.ComparePhase.Enable = response.PhaseMatchingEnabled.FactoryValue;
            this.ComparePhase.Phase = response.PhaseMatchingValue.FactoryValue;
            this.ComparePhase.Freq = response.PhaseMatchingFrequency.FactoryValue;
            this.MinGainLimit.Enable = this.GraphicsSettings.response.MinimumGainEnabled.FactoryValue;
            this.MinGainLimit.MinGain = this.GraphicsSettings.response.MinimumGainValue.FactoryValue;
        end
              
        function restoreCSDPreferences(this)
            csdesigner = this.GraphicsSettings.csdesigner;
            this.CompensatorFormat = csdesigner.CompensatorFormat.FactoryValue;
            this.ShowSystemPZ = csdesigner.ShowSystemPZ.FactoryValue;
            this.SISOToolStyle.Color.System = csdesigner.SystemColor.FactoryValue;
            this.SISOToolStyle.Color.PreFilter = csdesigner.PreFilterColor.FactoryValue;
            this.SISOToolStyle.Color.ClosedLoop = csdesigner.ClosedLoopColor.FactoryValue;
            this.SISOToolStyle.Color.Compensator = csdesigner.CompensatorColor.FactoryValue;
            this.SISOToolStyle.Color.Response = csdesigner.ResponseColor.FactoryValue;
            this.SISOToolStyle.Color.Margin = csdesigner.MarginColor.FactoryValue;
            this.SISOToolStyle.Marker.ClosedLoop = csdesigner.ClosedLoopMarker.FactoryValue;

            this.StartUpMsgBox.SISOtool = csdesigner.ShowStartupDialog.FactoryValue;
            this.StartUpMsgBox.LTIviewer = this.GraphicsSettings.ltiviewer.ShowStartupDialog.FactoryValue;    
        end

        function restorePIDTunerPreferences(this)
            % pidtuner
            pidtuner = this.GraphicsSettings.pidtuner;
            this.PIDTunerPreferences.PhaseMargin = pidtuner.PhaseMargin.FactoryValue;
            this.PIDTunerPreferences.DefaultTableMode = pidtuner.DefaultTableMode.FactoryValue;
            this.PIDTunerPreferences.DefaultPlotType = pidtuner.DefaultPlotType.FactoryValue;
            this.PIDTunerPreferences.BlockColor = pidtuner.BlockColor.FactoryValue;
            this.PIDTunerPreferences.D2CMethod = pidtuner.D2CMethod.FactoryValue;
            this.PIDTunerPreferences.TunedColor = pidtuner.TunedColor.FactoryValue;
            this.PIDTunerPreferences.DisturbanceLocation = pidtuner.DisturbanceLocation.FactoryValue;
            this.PIDTunerPreferences.DefaultWelcomeDialog = pidtuner.DefaultWelcomeDialog.FactoryValue;
            this.PIDTunerPreferences.DefaultLegendMode = pidtuner.DefaultLegendMode.FactoryValue;
            this.PIDTunerPreferences.DefaultDesignMode = pidtuner.DefaultDesignMode.FactoryValue;
            this.PIDTunerPreferences.Version = pidtuner.Version.FactoryValue;
        end
        
        function load(this,filename,optionalArguments)
            arguments
                this
                filename = ''
                optionalArguments.SaveFlagToFile = true
            end
            % Loads toolbox preferences from a disk file.

            if isempty(this) || ~isvalid(this)
                error(message( 'MATLAB:class:InvalidHandle'))
            end

            if isempty(filename)
                %---If no file name is specified, load from default preference file
                filename = this.defaultfile;
            else
                if ~contains(filename,'.mat')
                    filename = [filename,'.mat'];
                end
            end

            s = settings;
            controllib.settings.internal.migrateGraphicsSettingsFromPrefdir(s.controlshared.graphics,...
                FileName=filename,SaveFlagToFile=optionalArguments.SaveFlagToFile);
            pushSettingsToPreferences(this);

            try
                s = load(filename);
                loadLocalUpdateValues(this,s.p.Version);
            catch ME

            end
        end

        function save(this,fileName)
            arguments
                this
                fileName = ''
            end

            %% Save Toolbox Preferences to a disk file.

            if isempty(this) || ~isvalid(this)
                error(message( 'MATLAB:class:InvalidHandle'))
            end
            
            pushPreferencesToSettingsPersonalValue(this);

            if ~isempty(fileName)
                %---We need to save the preferences in structure 'p'
                p = get(this);
                p = rmfield(p,["Dialog" "LocalMinGainLimit" "LocalMagnitudeScale" ...
                    "LocalPhaseWrappingBranch"]);

                %---Write preferences to disk
                save(fileName,'p');
            end
        end

    end

    %% Private Methods
    methods (Access=private)
        function updateMagDependents(this)
            %% Update dependent properties of magnitude unit.

            if ~isempty(this.LocalMinGainLimit)
                currUnit = this.MagnitudeUnits;
                preMinGain = this.LocalMinGainLimit.MinGain;
                preUnit = char(setdiff(["dB" "abs"],currUnit));
                this.LocalMinGainLimit.MinGain = unitconv(preMinGain, ...
                    preUnit,currUnit);
            end
            if ~isempty(this.LocalMagnitudeScale)
                this.LocalMagnitudeScale = 'linear';
            end
        end
        
        function filename = defaultfile(this) %#ok<MANU>
            % Returns the name of user's default preference file.
            filename = fullfile(prefdir(1),'cstprefs.mat');
        end

        function dirty = loadLocalMapValues(this,p)
            %% Map values into preferences object (from structure p to object h)
            dirty = 0;
            %---Version info
            newver = this.Version;
            if isfield(p,'Version')
                oldver = p.Version;
            else
                oldver = 0;
            end
            %---Field names
            fnp = fieldnames(p);
            fnh = setdiff(fieldnames(this),["Dialog" "LocalMinGainLimit" ...
                "LocalMagnitudeScale" "LocalPhaseWrappingBranch",...
                "JavaFontSize","JavaFontP","JavaFontB","JavaFontI"]);
            %---Quick set (property list unchanged)
            if isequal(sort(fnp),sort(fnh))
                set(this,p);
                %---Partial set (property list has changed)
            else
                %---Copy any common properties to the new version
                hs = get(this);
                for n=1:length(fnp)
                    if isfield(hs,fnp{n})
                        set(this,fnp{n},p.(fnp{n}));
                    end
                end
            end
            %---Restore new version number (since the set may have wiped it out)
            this.Version = newver;
            %---Custom version-specific modifications
            loadLocalUpdateValues(this,oldver);
            %---If anything has changed, force a save
            p2 = get(this);
            p2 = rmfield(p2,["Dialog" "LocalMinGainLimit" ...
                "LocalMagnitudeScale" "LocalPhaseWrappingBranch","VersionFactoryValue"]);
            p3 = rmfield(p,["JavaFontSize","JavaFontB","JavaFontI","JavaFontP"]);
            if ~isequal(p2,p3)
                dirty = 1;
            end
        end

        function loadLocalUpdateValues(this,oldver)
            %% Update old property values to new equivalent values.

            hs = get(this);
            %---Old CompensatorFormat options
            if isfield(hs,'CompensatorFormat')
                if strcmpi(this.CompensatorFormat,'ZPK1')
                    this.CompensatorFormat = 'ZeroPoleGain';
                elseif strcmpi(this.CompensatorFormat,'TimeConstant')
                    this.CompensatorFormat = 'TimeConstant1';
                end
            end

            %---Prefilter color change (v1.1)
            if isfield(hs,'SISOToolStyle')&&(oldver<1.1)
                tmp = this.SISOToolStyle;
                tmp.Color.PreFilter = [0 0.7 0];
                this.SISOToolStyle = tmp;
            end

            %---Map FrequencyUnit of rad/s or rad/sec to auto (v2.0)
            if isfield(hs,'FrequencyUnits')&&(oldver<2.0)&& strncmpi(hs.FrequencyUnits,'rad/',4)
                this.FrequencyUnits = 'auto';
            end

            %---Apply PID Tool version information
            if (oldver<3.0)
                this.PIDTunerPreferences.Version = 2.0;
            end

            %---Apply Graphics Version 2 settings
            if (oldver<4.0)
                SysFontSize = get(0,'DefaultAxesFontSize');
                % Title
                if this.TitleFontSize == 8
                    this.TitleFontSize = SysFontSize * get(0,'DefaultAxesTitleFontSizeMultiplier');
                end
                if strcmpi(this.TitleFontWeight,'normal')
                    this.TitleFontWeight = get(0,'DefaultAxesTitleFontWeight');
                end
                % Labels
                if this.XYLabelsFontSize == 8
                    this.XYLabelsFontSize = SysFontSize * get(0,'DefaultAxesLabelFontSizeMultiplier');
                end
                if this.IOLabelsFontSize == 8
                    this.IOLabelsFontSize = SysFontSize;
                end
            end
        end

        function pushPreferencesToSettingsPersonalValue(this)
            % style
            style = this.GraphicsSettings.style;
            style.Grid.PersonalValue = this.Grid;
            style.GridColor.PersonalValue = this.GridColor;
            style.TitleFontSize.PersonalValue = this.TitleFontSize;
            style.TitleFontWeight.PersonalValue = this.TitleFontWeight;
            style.TitleFontAngle.PersonalValue = this.TitleFontAngle;
            style.XYLabelsFontSize.PersonalValue = this.XYLabelsFontSize;
            style.XYLabelsFontAngle.PersonalValue = this.XYLabelsFontAngle;
            style.XYLabelsFontWeight.PersonalValue = this.XYLabelsFontWeight;
            style.IOLabelsFontSize.PersonalValue = this.IOLabelsFontSize;
            style.IOLabelsFontWeight.PersonalValue = this.IOLabelsFontWeight;
            style.IOLabelsFontAngle.PersonalValue = this.IOLabelsFontAngle;
            style.AxesFontSize.PersonalValue = this.AxesFontSize;
            style.AxesFontWeight.PersonalValue = this.AxesFontWeight;
            style.AxesFontAngle.PersonalValue = this.AxesFontAngle;
            style.AxesForegroundColor.PersonalValue = this.AxesForegroundColor;

            % units
            units = this.GraphicsSettings.units;
            units.TimeUnits.PersonalValue = this.TimeUnits;
            units.FrequencyUnits.PersonalValue = this.FrequencyUnits;
            units.FrequencyScale.PersonalValue = this.FrequencyScale;
            units.MagnitudeUnits.PersonalValue = this.MagnitudeUnits;
            units.MagnitudeScale.PersonalValue = this.MagnitudeScale;
            units.PhaseUnits.PersonalValue = this.PhaseUnits;

            % response
            response = this.GraphicsSettings.response;
            response.SettlingTimeThreshold.PersonalValue = this.SettlingTimeThreshold;
            response.RiseTimeLimits.PersonalValue = this.RiseTimeLimits;
            if strcmp(this.UnwrapPhase,'off')
                response.PhaseWrappingEnabled.PersonalValue = 'on';
            else
                response.PhaseWrappingEnabled.PersonalValue = 'off';
            end
            response.PhaseWrappingBranch.PersonalValue = this.PhaseWrappingBranch;
            response.PhaseMatchingEnabled.PersonalValue = this.ComparePhase.Enable;
            response.PhaseMatchingValue.PersonalValue = this.ComparePhase.Phase;
            response.PhaseMatchingFrequency.PersonalValue = this.ComparePhase.Freq;
            response.MinimumGainEnabled.PersonalValue = this.MinGainLimit.Enable;
            response.MinimumGainValue.PersonalValue = this.MinGainLimit.MinGain;

            % pidtuner
            pidtuner = this.GraphicsSettings.pidtuner;
            pidtuner.PhaseMargin.PersonalValue = this.PIDTunerPreferences.PhaseMargin;
            pidtuner.DefaultTableMode.PersonalValue = this.PIDTunerPreferences.DefaultTableMode;
            pidtuner.DefaultPlotType.PersonalValue = this.PIDTunerPreferences.DefaultPlotType;
            pidtuner.BlockColor.PersonalValue = this.PIDTunerPreferences.BlockColor;
            pidtuner.D2CMethod.PersonalValue = this.PIDTunerPreferences.D2CMethod;
            pidtuner.TunedColor.PersonalValue = this.PIDTunerPreferences.TunedColor;
            pidtuner.DisturbanceLocation.PersonalValue = this.PIDTunerPreferences.DisturbanceLocation;
            pidtuner.DefaultWelcomeDialog.PersonalValue = this.PIDTunerPreferences.DefaultWelcomeDialog;
            pidtuner.DefaultLegendMode.PersonalValue = this.PIDTunerPreferences.DefaultLegendMode;
            pidtuner.DefaultDesignMode.PersonalValue = this.PIDTunerPreferences.DefaultDesignMode;
            pidtuner.Version.PersonalValue = this.PIDTunerPreferences.Version;

            % csdesigner
            csdesigner = this.GraphicsSettings.csdesigner;
            csdesigner.CompensatorFormat.PersonalValue = this.CompensatorFormat;
            csdesigner.ShowSystemPZ.PersonalValue = this.ShowSystemPZ;
            csdesigner.SystemColor.PersonalValue = this.SISOToolStyle.Color.System;
            csdesigner.PreFilterColor.PersonalValue = this.SISOToolStyle.Color.PreFilter;
            csdesigner.ClosedLoopColor.PersonalValue = this.SISOToolStyle.Color.ClosedLoop;
            csdesigner.CompensatorColor.PersonalValue = this.SISOToolStyle.Color.Compensator;
            csdesigner.ResponseColor.PersonalValue = this.SISOToolStyle.Color.Response;
            csdesigner.MarginColor.PersonalValue = this.SISOToolStyle.Color.Margin;
            csdesigner.ClosedLoopMarker.PersonalValue = this.SISOToolStyle.Marker.ClosedLoop;

            csdesigner.ShowStartupDialog.PersonalValue = ...
                matlab.lang.OnOffSwitchState(this.StartUpMsgBox.SISOtool);
            this.GraphicsSettings.ltiviewer.ShowStartupDialog.PersonalValue = ...
                matlab.lang.OnOffSwitchState(this.StartUpMsgBox.LTIviewer);
        end

        function pushSettingsToPreferences(this)
            % style
            style = this.GraphicsSettings.style;
            this.Grid = style.Grid.ActiveValue;
            this.GridColor = style.GridColor.ActiveValue;
            this.TitleFontSize = style.TitleFontSize.ActiveValue;
            this.TitleFontWeight = style.TitleFontWeight.ActiveValue;
            this.TitleFontAngle = style.TitleFontAngle.ActiveValue;
            this.XYLabelsFontSize = style.XYLabelsFontSize.ActiveValue;
            this.XYLabelsFontAngle = style.XYLabelsFontAngle.ActiveValue;
            this.XYLabelsFontWeight = style.XYLabelsFontWeight.ActiveValue;
            this.IOLabelsFontSize = style.IOLabelsFontSize.ActiveValue;
            this.IOLabelsFontWeight = style.IOLabelsFontWeight.ActiveValue;
            this.IOLabelsFontAngle = style.IOLabelsFontAngle.ActiveValue;
            this.AxesFontSize = style.AxesFontSize.ActiveValue;
            this.AxesFontWeight = style.AxesFontWeight.ActiveValue;
            this.AxesFontAngle = style.AxesFontAngle.ActiveValue;
            this.AxesForegroundColor = style.AxesForegroundColor.ActiveValue;

            % units
            units = this.GraphicsSettings.units;
            this.TimeUnits = units.TimeUnits.ActiveValue;
            this.FrequencyUnits = units.FrequencyUnits.ActiveValue;
            this.FrequencyScale = units.FrequencyScale.ActiveValue;
            this.MagnitudeUnits = units.MagnitudeUnits.ActiveValue;
            this.MagnitudeScale = units.MagnitudeScale.ActiveValue;
            this.PhaseUnits = units.PhaseUnits.ActiveValue;

            % response
            response = this.GraphicsSettings.response;
            this.SettlingTimeThreshold = response.SettlingTimeThreshold.ActiveValue;
            this.RiseTimeLimits = response.RiseTimeLimits.ActiveValue;
            if strcmp(response.PhaseWrappingEnabled.ActiveValue,'off')
                this.UnwrapPhase = 'on';
            else
                this.UnwrapPhase = 'off';
            end
            this.PhaseWrappingBranch = response.PhaseWrappingBranch.ActiveValue;
            this.ComparePhase.Enable = response.PhaseMatchingEnabled.ActiveValue;
            this.ComparePhase.Phase = response.PhaseMatchingValue.ActiveValue;
            this.ComparePhase.Freq = response.PhaseMatchingFrequency.ActiveValue;
            this.MinGainLimit.Enable = this.GraphicsSettings.response.MinimumGainEnabled.ActiveValue;
            this.MinGainLimit.MinGain = this.GraphicsSettings.response.MinimumGainValue.ActiveValue;

            % pidtuner
            pidtuner = this.GraphicsSettings.pidtuner;
            this.PIDTunerPreferences.PhaseMargin = pidtuner.PhaseMargin.ActiveValue;
            this.PIDTunerPreferences.DefaultTableMode = pidtuner.DefaultTableMode.ActiveValue;
            this.PIDTunerPreferences.DefaultPlotType = pidtuner.DefaultPlotType.ActiveValue;
            this.PIDTunerPreferences.BlockColor = pidtuner.BlockColor.ActiveValue;
            this.PIDTunerPreferences.D2CMethod = pidtuner.D2CMethod.ActiveValue;
            this.PIDTunerPreferences.TunedColor = pidtuner.TunedColor.ActiveValue;
            this.PIDTunerPreferences.DisturbanceLocation = pidtuner.DisturbanceLocation.ActiveValue;
            this.PIDTunerPreferences.DefaultWelcomeDialog = pidtuner.DefaultWelcomeDialog.ActiveValue;
            this.PIDTunerPreferences.DefaultLegendMode = pidtuner.DefaultLegendMode.ActiveValue;
            this.PIDTunerPreferences.DefaultDesignMode = pidtuner.DefaultDesignMode.ActiveValue;
            this.PIDTunerPreferences.Version = pidtuner.Version.ActiveValue;

            % csdesigner
            csdesigner = this.GraphicsSettings.csdesigner;
            this.CompensatorFormat = csdesigner.CompensatorFormat.ActiveValue;
            this.ShowSystemPZ = csdesigner.ShowSystemPZ.ActiveValue;
            this.SISOToolStyle.Color.System = csdesigner.SystemColor.ActiveValue;
            this.SISOToolStyle.Color.PreFilter = csdesigner.PreFilterColor.ActiveValue;
            this.SISOToolStyle.Color.ClosedLoop = csdesigner.ClosedLoopColor.ActiveValue;
            this.SISOToolStyle.Color.Compensator = csdesigner.CompensatorColor.ActiveValue;
            this.SISOToolStyle.Color.Response = csdesigner.ResponseColor.ActiveValue;
            this.SISOToolStyle.Color.Margin = csdesigner.MarginColor.ActiveValue;
            this.SISOToolStyle.Marker.ClosedLoop = csdesigner.ClosedLoopMarker.ActiveValue;

            this.StartUpMsgBox.SISOtool = csdesigner.ShowStartupDialog.ActiveValue;
            this.StartUpMsgBox.LTIviewer = this.GraphicsSettings.ltiviewer.ShowStartupDialog.ActiveValue;
        end
    end

    %% Static method
    methods(Static)
        function prefs = getInstance
            %% Returns singleton instance.

            mlock
            persistent instance
            if isempty(instance) || ~isvalid(instance)
                instance = controllib.widget.internal.cstprefs.ToolboxPreferences;
            end
            prefs = instance;
        end
    end
end