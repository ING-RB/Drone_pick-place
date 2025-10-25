function migrateGraphicsSettingsFromPrefdir(graphics,optionalArguments)
% controllib.settings.internal.migrateGraphicsSettingsFromPrefdir(graphicsSettingsGroup,FileName=<path to cstprefs.mat>,SaveFlagToFile=true)

% Copyright 2023 The MathWorks, Inc.
arguments
    graphics
    optionalArguments.FileName = ''
    optionalArguments.SaveFlagToFile = true
end

% Migrate if cstprefs.mat file exists
if isempty(optionalArguments.FileName)
    fileName = fullfile(prefdir(1),'cstprefs.mat');
else
    fileName = optionalArguments.FileName;
end

if exist(fileName)
    data = load(fileName);
    % Migrate if data hasn't been migrated before
    if ~isfield(data,'IsDataMigratedToSettingsAPI') || ~data.IsDataMigratedToSettingsAPI
        oldPhaseUnits = graphics.units.PhaseUnits.ActiveValue;

        migrateStyleSettings(graphics.style,data.p);
        migrateUnitsSettings(graphics.units,data.p);
        migrateResponseSettings(graphics.response,data.p);
        migratePIDTunerSettings(graphics.pidtuner,data.p);
        migrateCSDesignerSettings(graphics.csdesigner,data.p);
        migrateUISettings(graphics.ui,data.p);
        
        if ~isfield(data.p,'PhaseWrappingBranch')
            % There are older preference mat files that do not contain
            % information on PhaseWrappingBranch. For these cases, convert
            % the current phase wrapping branch value if the phase units
            % changes.
            if hasPersonalValue(graphics.response.PhaseWrappingBranch)
                if ~strcmp(oldPhaseUnits,graphics.units.PhaseUnits.PersonalValue)
                    if strcmp(oldPhaseUnits,'deg')
                        graphics.response.PhaseWrappingBranch.PersonalValue = ...
                            deg2rad(graphics.response.PhaseWrappingBranch.PersonalValue);
                    else
                        graphics.response.PhaseWrappingBranch.PersonalValue = ...
                            rad2deg(graphics.response.PhaseWrappingBranch.PersonalValue);
                    end
                end
            end
        end
        % Save flag in mat file to indicate that data has been migrated to
        % settings.
        if optionalArguments.SaveFlagToFile
            data.IsDataMigratedToSettingsAPI = true;
            save(fileName,'-struct',"data");
        end
    end
end
end

%% Migration methods
function migrateStyleSettings(style,prefs)
% Title
setPersonalValue(style.TitleFontSize,prefs.TitleFontSize);
setPersonalValue(style.TitleFontWeight,prefs.TitleFontWeight);
setPersonalValue(style.TitleFontAngle,prefs.TitleFontAngle);

% XYLabels
setPersonalValue(style.XYLabelsFontSize,prefs.XYLabelsFontSize);
setPersonalValue(style.XYLabelsFontWeight,prefs.XYLabelsFontWeight);
setPersonalValue(style.XYLabelsFontAngle,prefs.XYLabelsFontAngle);

% XYLabels
setPersonalValue(style.IOLabelsFontSize,prefs.IOLabelsFontSize);
setPersonalValue(style.IOLabelsFontWeight,prefs.IOLabelsFontWeight);
setPersonalValue(style.IOLabelsFontAngle,prefs.IOLabelsFontAngle);

% XYLabels
setPersonalValue(style.AxesFontSize,prefs.AxesFontSize);
setPersonalValue(style.AxesFontWeight,prefs.AxesFontWeight);
setPersonalValue(style.AxesFontAngle,prefs.AxesFontAngle);

% Grid
setPersonalValue(style.Grid,matlab.lang.OnOffSwitchState(prefs.Grid));
if isfield(prefs,'GridColor')
    setPersonalValue(style.GridColor,prefs.GridColor);
end

% AxesForegroundColor
setPersonalValue(style.AxesForegroundColor,prefs.AxesForegroundColor);
end

function migrateUnitsSettings(units,prefs)
if isfield(prefs,'TimeUnits')
    setPersonalValue(units.TimeUnits,prefs.TimeUnits);
end
if isfield(prefs,'FrequencyUnits') && strncmpi(prefs.FrequencyUnits,'rad/',4) && ...
        isfield(prefs,'Version') && (prefs.Version<2.0)
    if hasPersonalValue(units.FrequencyUnits)
        clearPersonalValue(units.FrequencyUnits);
    end
else
    setPersonalValue(units.FrequencyUnits,prefs.FrequencyUnits);
end
setPersonalValue(units.FrequencyScale,prefs.FrequencyScale);
setPersonalValue(units.MagnitudeUnits,prefs.MagnitudeUnits);
setPersonalValue(units.MagnitudeScale,prefs.MagnitudeScale);
setPersonalValue(units.PhaseUnits,prefs.PhaseUnits);
end

function migrateResponseSettings(response,prefs)
% Time response settings
setPersonalValue(response.SettlingTimeThreshold,prefs.SettlingTimeThreshold);
setPersonalValue(response.RiseTimeLimits,prefs.RiseTimeLimits);

% Phase Wrapping
if strcmp(prefs.UnwrapPhase,'on')
    setPersonalValue(response.PhaseWrappingEnabled,'off');
else
    setPersonalValue(response.PhaseWrappingEnabled,'on');
end
if isfield(prefs,'PhaseWrappingBranch')
    setPersonalValue(response.PhaseWrappingBranch,prefs.PhaseWrappingBranch);
end

% Phase Matching
if isfield(prefs,'ComparePhase')
    setPersonalValue(response.PhaseMatchingEnabled,prefs.ComparePhase.Enable);
    setPersonalValue(response.PhaseMatchingValue,prefs.ComparePhase.Phase);
    setPersonalValue(response.PhaseMatchingFrequency,prefs.ComparePhase.Freq);
end

% Minimum Gain
if isfield(prefs,'MinGainLimit')
    setPersonalValue(response.MinimumGainEnabled,prefs.MinGainLimit.Enable);
    setPersonalValue(response.MinimumGainValue,prefs.MinGainLimit.MinGain);
end
end

function migratePIDTunerSettings(pidtuner,prefs)
if isfield(prefs,'PIDTunerPreferences')
    setPersonalValue(pidtuner.PhaseMargin,prefs.PIDTunerPreferences.PhaseMargin);
    setPersonalValue(pidtuner.DisturbanceLocation,prefs.PIDTunerPreferences.DisturbanceLocation);
    setPersonalValue(pidtuner.D2CMethod,prefs.PIDTunerPreferences.D2CMethod);
    setPersonalValue(pidtuner.TunedColor,prefs.PIDTunerPreferences.TunedColor);
    setPersonalValue(pidtuner.BlockColor,prefs.PIDTunerPreferences.BlockColor);
    setPersonalValue(pidtuner.DefaultDesignMode,prefs.PIDTunerPreferences.DefaultDesignMode);
    setPersonalValue(pidtuner.DefaultTableMode,prefs.PIDTunerPreferences.DefaultTableMode);
    setPersonalValue(pidtuner.DefaultPlotType,prefs.PIDTunerPreferences.DefaultPlotType);
    setPersonalValue(pidtuner.DefaultLegendMode,prefs.PIDTunerPreferences.DefaultLegendMode);
    setPersonalValue(pidtuner.DefaultWelcomeDialog,prefs.PIDTunerPreferences.DefaultWelcomeDialog);
    setPersonalValue(pidtuner.Version,prefs.PIDTunerPreferences.Version);
end
end

function migrateCSDesignerSettings(csdesigner,prefs)
setPersonalValue(csdesigner.CompensatorFormat,prefs.CompensatorFormat);
setPersonalValue(csdesigner.ShowSystemPZ,prefs.ShowSystemPZ);
setPersonalValue(csdesigner.ClosedLoopColor,prefs.SISOToolStyle.Color.ClosedLoop);
setPersonalValue(csdesigner.CompensatorColor,prefs.SISOToolStyle.Color.Compensator);
setPersonalValue(csdesigner.MarginColor,prefs.SISOToolStyle.Color.Margin);
setPersonalValue(csdesigner.PreFilterColor,prefs.SISOToolStyle.Color.PreFilter);
setPersonalValue(csdesigner.ResponseColor,prefs.SISOToolStyle.Color.Response);
setPersonalValue(csdesigner.SystemColor,prefs.SISOToolStyle.Color.System);
setPersonalValue(csdesigner.ClosedLoopMarker,prefs.SISOToolStyle.Marker.ClosedLoop);
end

function migrateUISettings(ui,prefs)
setPersonalValue(ui.UIFontSize,prefs.UIFontSize);
end

%% Check factory value and set personal value
function setPersonalValue(setting,savedPreferenceValue)
setting.PersonalValue = savedPreferenceValue;
end

