function hmenu = lticharmenu(hplot, mChar, plotType)
% LTICHARMENU   Adds response characteristic menus for LTI plots.
%
% Create a group of characteristic submenu items appropriate for the plotType.
% Parent these menus to the previously created context menu mChar. Note hplot
% is a @respplot object.

% Author(s): James Owen
% Copyright 1986-2011 The MathWorks, Inc.

% Add classes to be included for compiler for CST plots
%#function resppack.TimeFinalValueData
%#function resppack.TimeFinalValueView
%#function resppack.StepPeakRespData
%#function resppack.StepPeakRespView
%#function resppack.SettleTimeData
%#function resppack.SettleTimeView
%#function resppack.TransientTimeData
%#function resppack.TransientTimeView
%#function resppack.StepRiseTimeData
%#function resppack.StepRiseTimeView
%#function resppack.StepSteadyStateView
%#function wavepack.TimePeakAmpData 
%#function wavepack.TimePeakAmpView
%#function resppack.SimInputPeakView
%#function wavepack.FreqPeakGainData
%#function wavepack.FreqPeakGainView
%#function resppack.MinStabilityMarginData
%#function resppack.BodeStabilityMarginView
%#function resppack.AllStabilityMarginData
%#function resppack.BodeStabilityMarginView
%#function resppack.NicholsPeakRespView
%#function resppack.NyquistStabilityMarginView
%#function resppack.SigmaPeakRespData
%#function resppack.SigmaPeakRespView
%#function resppack.NyquistPeakRespView
%#function resppack.FreqPeakRespData
switch plotType
   case 'step'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'resppack.StepPeakRespData', 'resppack.StepPeakRespView');

      hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strRiseTime')),...
         'resppack.StepRiseTimeData', 'resppack.StepRiseTimeView');

      hmenu(3) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strSettlingTime')),...
         'resppack.SettleTimeData', 'resppack.SettleTimeView');

      hmenu(4) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strTransientTime')),...
         'resppack.TransientTimeData', 'resppack.TransientTimeView');

      hmenu(5) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strSteadyState')),...
         'resppack.TimeFinalValueData', 'resppack.StepSteadyStateView');

   case 'impulse'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'wavepack.TimePeakAmpData', 'wavepack.TimePeakAmpView');

      hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strTransientTime')),...
         'resppack.TransientTimeData', 'resppack.TransientTimeView');

   case 'initial'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'wavepack.TimePeakAmpData', 'wavepack.TimePeakAmpView');

      hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strTransientTime')),...
         'resppack.TransientTimeData', 'resppack.TransientTimeView');

   case 'lsim'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'wavepack.TimePeakAmpData', 'wavepack.TimePeakAmpView',...
         'resppack.SimInputPeakView');

   case 'bode'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'wavepack.FreqPeakGainData', 'wavepack.FreqPeakGainView');

      s = size(getaxes(hplot));
      if prod(s(1:2)) == 1
         hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strMinimumStabilityMargins')),...
            'resppack.MinStabilityMarginData', 'resppack.BodeStabilityMarginView');

         hmenu(3) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strAllStabilityMargins')),...
            'resppack.AllStabilityMarginData', 'resppack.BodeStabilityMarginView');
      end

   case 'nichols'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'wavepack.FreqPeakGainData', 'resppack.NicholsPeakRespView');

      s = size(getaxes(hplot));
      if prod(s(1:2)) == 1
         hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strMinimumStabilityMargins')),...
            'resppack.MinStabilityMarginData', 'resppack.NicholsStabilityMarginView');

         hmenu(3) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strAllStabilityMargins')),...
            'resppack.AllStabilityMarginData', 'resppack.NicholsStabilityMarginView');
      end

   case 'nyquist'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'resppack.FreqPeakRespData', 'resppack.NyquistPeakRespView');

      s = size(getaxes(hplot));
      if prod(s(1:2)) == 1
         hmenu(2) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strMinimumStabilityMargins')),...
            'resppack.MinStabilityMarginData', 'resppack.NyquistStabilityMarginView');

         hmenu(3) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strAllStabilityMargins')),...
            'resppack.AllStabilityMarginData', 'resppack.NyquistStabilityMarginView');
      end

   case 'sigma'
      hmenu(1) = hplot.addCharMenu(mChar, getString(message('Controllib:plots:strPeakResponse')),...
         'resppack.SigmaPeakRespData', 'resppack.SigmaPeakRespView');
end
