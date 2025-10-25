classdef GraphicsFactorySettings < matlab.settings.internal.FactorySettingsDefinition
    % GraphicsFactorySettings

    % Copyright 2023 The MathWorks, Inc.
    methods (Static)
        function createTree(graphics)
            % Style related settings
            styleGroup = graphics.addGroup('style',Hidden=false);
            createStyleSettings(styleGroup);

            % Units related settings
            unitsGroup = graphics.addGroup('units',Hidden=false);
            createUnitsSettings(unitsGroup);

            % Response related settings
            responseGroup = graphics.addGroup('response',Hidden=false);
            createResponseSettings(responseGroup);

            % PIDTuner related settings
            pidTunerGroup = graphics.addGroup('pidtuner',Hidden=false);
            createPIDTunerSettings(pidTunerGroup);

            % CSDesigner related settings
            csdesignerGroup = graphics.addGroup('csdesigner',Hidden=false);
            createCSDesignerSettings(csdesignerGroup);

            % LTI Viewer related settings
            ltiviewerGroup = graphics.addGroup('ltiviewer');
            createLTIViewerSettings(ltiviewerGroup);

            % Graphics settings
            uiGroup = graphics.addGroup('ui',Hidden=false);
            createUISettings(uiGroup);
        end

        function u = createUpgraders()
            u = matlab.settings.SettingsFileUpgrader('v1');
        end
    end

    methods (Access = private)
        

    end
end

%% Settings creation
function createStyleSettings(styleGroup)
% Grid
styleGroup.addSetting('Grid',FactoryValue=matlab.lang.OnOffSwitchState('off'),...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffSwitchState,Hidden=false);
styleGroup.addSetting('GridColor',FactoryValue=[0.15 0.15 0.15],...
    ValidationFcn=@validatecolor,Hidden=false);

% Title
styleGroup.addSetting('TitleFontSize',FactoryValue=11,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);
styleGroup.addSetting('TitleFontWeight',FactoryValue='bold',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontWeight,Hidden=false);
styleGroup.addSetting('TitleFontAngle',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontAngle,Hidden=false);

% XYLabel
styleGroup.addSetting('XYLabelsFontSize',FactoryValue=11,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);
styleGroup.addSetting('XYLabelsFontWeight',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontWeight,Hidden=false);
styleGroup.addSetting('XYLabelsFontAngle',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontAngle,Hidden=false);

% Axes
styleGroup.addSetting('AxesFontSize',FactoryValue=10,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);
styleGroup.addSetting('AxesFontWeight',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontWeight,Hidden=false);
styleGroup.addSetting('AxesFontAngle',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontAngle,Hidden=false);

% IOLabels
styleGroup.addSetting('IOLabelsFontSize',FactoryValue=10,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);
styleGroup.addSetting('IOLabelsFontWeight',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontWeight,Hidden=false);
styleGroup.addSetting('IOLabelsFontAngle',FactoryValue='normal',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFontAngle,Hidden=false);

% AxesForeground
s = styleGroup.addSetting('AxesForegroundColor',FactoryValue=[0.4 0.4 0.4],...
    ValidationFcn=function_handle.empty,Hidden=false);
end

function createUnitsSettings(unitsGroup)
% Frequency
unitsGroup.addSetting('FrequencyUnits',FactoryValue='auto',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidFrequencyUnitWithAuto,Hidden=false);
unitsGroup.addSetting('FrequencyScale',FactoryValue='log',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidAxisScale,Hidden=false);

% Magnitude
unitsGroup.addSetting('MagnitudeUnits',FactoryValue='dB',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidMagnitudeUnit,Hidden=false);
unitsGroup.addSetting('MagnitudeScale',FactoryValue='linear',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidAxisScale,Hidden=false);

% Phase
unitsGroup.addSetting('PhaseUnits',FactoryValue='deg',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidPhaseUnit,Hidden=false);

% Time
unitsGroup.addSetting('TimeUnits',FactoryValue='auto',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidTimeUnitWithAuto,Hidden=false);
end

function createResponseSettings(responseGroup)
% Time response related
responseGroup.addSetting('SettlingTimeThreshold',FactoryValue=0.02,...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidSettlingTimeThreshold,Hidden=false);
responseGroup.addSetting('RiseTimeLimits',FactoryValue=[0.1 0.9],...
    ValidationFcn=@controllib.chart.internal.utils.mustBeValidRiseTimeLimits,Hidden=false);

% Phase related
responseGroup.addSetting('PhaseWrappingEnabled',FactoryValue='off',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffChar,Hidden=false);
responseGroup.addSetting('PhaseWrappingBranch',FactoryValue=-180,...
    ValidationFcn=@matlab.settings.mustBeNumericScalar,Hidden=false);
responseGroup.addSetting('PhaseMatchingEnabled',FactoryValue='off',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffChar,Hidden=false);
responseGroup.addSetting('PhaseMatchingValue',FactoryValue=0,...
    ValidationFcn=@matlab.settings.mustBeNumericScalar,Hidden=false);
responseGroup.addSetting('PhaseMatchingFrequency',FactoryValue=0,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);

% Magnitude related
responseGroup.addSetting('MinimumGainEnabled',FactoryValue='off',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffChar,Hidden=false);
responseGroup.addSetting('MinimumGainValue',FactoryValue=0,...
    ValidationFcn=@matlab.settings.mustBeNumericScalar,Hidden=false);
end

function createPIDTunerSettings(pidtunerGroup)
% PIDTuner App related
pidtunerGroup.addSetting('PhaseMargin',FactoryValue=60,...
    ValidationFcn=@mustBeNonnegative,Hidden=false);
pidtunerGroup.addSetting('DisturbanceLocation',FactoryValue='input',Hidden=false);
pidtunerGroup.addSetting('D2CMethod',FactoryValue='zoh',Hidden=false);
pidtunerGroup.addSetting('TunedColor',FactoryValue=[0 0 1],...
    ValidationFcn=@validatecolor,Hidden=false);
pidtunerGroup.addSetting('BlockColor',FactoryValue=[0.7 0.7 0.7],...
    ValidationFcn=@validatecolor,Hidden=false);
pidtunerGroup.addSetting('DefaultDesignMode',FactoryValue='basic',Hidden=false);
pidtunerGroup.addSetting('DefaultTableMode',FactoryValue='off',Hidden=false);
pidtunerGroup.addSetting('DefaultPlotType',FactoryValue='tracking',Hidden=false);
pidtunerGroup.addSetting('DefaultLegendMode',FactoryValue='on',Hidden=false);
pidtunerGroup.addSetting('DefaultWelcomeDialog',FactoryValue='on',Hidden=false);
pidtunerGroup.addSetting('Version',FactoryValue=2,Hidden=false);
end

function createCSDesignerSettings(csdesignerGroup)
% Control System Designer App related
csdesignerGroup.addSetting('CompensatorFormat',FactoryValue='TimeConstant1',Hidden=false);
csdesignerGroup.addSetting('ShowSystemPZ',FactoryValue='on',...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffChar,Hidden=false);
csdesignerGroup.addSetting('ClosedLoopColor',FactoryValue=[1 0 0.8],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('CompensatorColor',FactoryValue=[1 0 0],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('MarginColor',FactoryValue=[0.8 0.5 0],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('PreFilterColor',FactoryValue=[0 0.7 0],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('ResponseColor',FactoryValue=[0 0 1],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('SystemColor',FactoryValue=[0 0 1],...
    ValidationFcn=@validatecolor,Hidden=false);
csdesignerGroup.addSetting('ClosedLoopMarker',FactoryValue='s',Hidden=false);
csdesignerGroup.addSetting('ShowStartupDialog',FactoryValue=matlab.lang.OnOffSwitchState('on'),...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffSwitchState,Hidden=false);
end

function createLTIViewerSettings(ltiviewerGroup)
% Linear System Analyzer related
ltiviewerGroup.addSetting('ShowStartupDialog',FactoryValue=matlab.lang.OnOffSwitchState('on'),...
    ValidationFcn=@controllib.chart.internal.utils.mustBeOnOffSwitchState,Hidden=false);
end

function createUISettings(uiGroup)
% UIFontSize
uiGroup.addSetting('UIFontSize',FactoryValue=8,...
    ValidationFcn=@mustBePositive,Hidden=false);
end