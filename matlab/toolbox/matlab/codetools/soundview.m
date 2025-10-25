function hfig = soundview(varargin)
%SOUNDVIEW View and play sound with replay button
% SOUNDVIEW has been removed.
% Use the AUDIOREAD function to read a sound file and return a sample.
% Use the PLOT function to plot the sample, and use the sound function to
% play the sample.

% Copyright 1984-2023 The MathWorks, Inc.

me = MException(message("MATLAB:soundview:DeprecationMessage"));
me = me.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection('soundview','audioread'));
throw(me);