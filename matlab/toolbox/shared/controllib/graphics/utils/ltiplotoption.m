function p = ltiplotoption(PlotType,OptionsObject,Pref,NewRespPlot,h)
%LTIPLOTOPTION creates an appropriate plot options object.
%
%  The plotoption p returned is based on the state of NewRespPlot.
% 
%  Inputs:
%   PlotType = Plot type such as bode, etc.
%   OptionsObject = [] or a PlotOptions object
%   Pref = Preference object (tbxprefs or viewprefs)
%   NewRespPot = boolean true if plot is a new respplot
%   h = respplot handle or empty
%
%  Outputs:
%  p = PlotOptions Object
%  NewPlot = true if ax nexplot property is replace
%  h = [] or handle to resppack object

%  Copyright 1986-2021 The MathWorks, Inc.

% Create Options Object
if NewRespPlot
    % New respplot
    updateflag = true;
    switch PlotType
        case 'bode'
            if isa(OptionsObject,'plotopts.BodeOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.BodeOptions;
            end
        case 'hsv'
            if isa(OptionsObject,'plotopts.HSVOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.HSVOptions;
            end
        case 'impulse'
            if isa(OptionsObject,'plotopts.TimeOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.TimeOptions;
                p.Title.String = getString(message('Controllib:plots:strImpulseResponse'));
            end
        case 'initial'
            if isa(OptionsObject,'plotopts.TimeOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.TimeOptions;
                p.Title.String = getString(message('Controllib:plots:strResponseToInitialConditions'));
            end
        case 'iopzmap'
            if isa(OptionsObject,'plotopts.PZOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.PZOptions;
            end
        case 'lsim'
            if isa(OptionsObject,'plotopts.TimeOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.TimeOptions;
                p.Title.String = getString(message('Controllib:plots:strLinearSimulationResults'));
            end
        case 'nichols'
            if isa(OptionsObject,'plotopts.NicholsOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.NicholsOptions;
            end
        case 'nyquist'
            if isa(OptionsObject,'plotopts.NyquistOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.NyquistOptions;
            end
        case 'pzmap'
            if isa(OptionsObject,'plotopts.PZOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.PZOptions;
            end
        case 'rlocus'
            if isa(OptionsObject,'plotopts.PZOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.PZOptions;
                p.Title.String = getString(message('Controllib:plots:strRootLocus'));
            end
        case 'sectorplot'
            if isa(OptionsObject,'plotopts.SectorPlotOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.SectorPlotOptions;
            end
            
        case 'dirindex'
            if isa(OptionsObject,'plotopts.SectorPlotOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.SectorPlotOptions;
            end
            % Force scale to linear because index can be negative
            p.IndexScale = 'linear';
      
        case 'sigma'
            if isa(OptionsObject,'plotopts.SigmaOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.SigmaOptions;
            end
        case 'step'
            if isa(OptionsObject,'plotopts.TimeOptions')
                p = OptionsObject;
                updateflag = false;
            else
                p = plotopts.TimeOptions;
                p.Title.String = getString(message('Controllib:plots:strStepResponse'));
            end
       case 'noisespectrum'
          if isa(OptionsObject,'plotopts.SpectrumOptions')
             p = OptionsObject;
             updateflag = false;
          else
             p = plotopts.SpectrumOptions;
          end
       case 'diskmargin'
          if isa(OptionsObject,'plotopts.DiskMarginOptions')
             p = OptionsObject;
             updateflag = false;
          else
             p = plotopts.DiskMarginOptions;
          end
    end

    % Update default options object 
    if updateflag
        mapCSTPrefs(p,Pref);
        % Copy options to new object
        if ~isempty(OptionsObject)
            p = copyPlotOptions(p,OptionsObject);
        end
    end

else
    % Not a new respplot
    % get current plotoptions
    p = getoptions(h);
    % Copy specified options to current options
    if ~isempty(OptionsObject)
        p = copyPlotOptions(p,OptionsObject);
    end
end


