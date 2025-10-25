function p = spectrumoptions(varargin)
%SPECTRUMOPTIONS Creates option list for spectrum plot.
%
%   P =  SPECTRUMOPTIONS returns the default options for spectrum plots.
%   This list of options allows you to customize the plot appearance
%   from the command line. For example
%         P = spectrumoptions;
%         % Set frequency units to Hz and scale to linear 
%         P.FreqUnits = 'Hz'; 
%         P.FreqScale = 'linear'
%         % Set confidence region SD value to 3
%         P.ConfidenceRegionNumberSD = 3;
%         % Create plot with the options specified by P
%         h = spectrumplot(sys,P);
%   creates a spectrum plot for identified model sys such that the
%   frequency axis is linear and uses 'Hz' units. If you turn on the
%   Confidence Region characteristic, the confidence region shown uses 3 sd
%   uncertainty.
%
%   P = SPECTRUMOPTIONS('identpref') initializes the plot options with the
%   System Identification Toolbox preferences.
%
%   Available options include:
%      Title, XLabel, YLabel         Label text and style
%      TickLabel                     Tick label style
%      Grid   [off|on]               Show or hide the grid 
%      GridColor                     Color of grid lines. Default: [0.1500 0.1500 0.1500]
%      XlimMode, YlimMode            Limit modes
%      Xlim, Ylim                    Axes limits
%      IOGrouping                    Grouping of input-output pairs
%         [none|inputs|outputs|all] 
%      InputLabels, OutputLabels     Input and output label styles
%      InputVisible, OutputVisible   Visibility of input and output
%                                    channels
%      FreqUnits                     Frequency units
%      FreqScale [linear|log]        Frequency scale
%      MagUnits [dB|abs]             Magnitude units
%      MagScale [linear|log]         Magnitude scale
%      MagLowerLimMode [auto|manual] Enables a lower magnitude limit
%      MagLowerLim                   Specifies the lower magnitude limit
%      ConfidenceRegionNumberSD      Number of standard deviations to
%                                    use when displaying the confidence
%                                    region characteristic for identified 
%                                    models
%
%   See also SPECTRUMPLOT, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

p = plotopts.SpectrumOptions(varargin{:});
