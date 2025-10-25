function stop = callAllOptimOutputAndPlotFcns(x,optimValues,state, ...
        objectiveSenseManager,outputfcns,plotfcns,varargin)
%

%CALLALLOPTIMOUTPUTANDPLOTFCNS Wrap call to output and plot functions to
%   account for objective sense (min/max/constant offset values).
%
%   STOP = CALLALLOPTIMOUTPUTANDPLOTFCNS(x,optimValues,state,
%   objectiveSenseManager,outputfcns,plotfcns,varargin) is an output
%   function wrapper for the user's output and plot functions to account
%   for objective sense (min/max/constant offset values).

%   Copyright 2022-2023 The MathWorks, Inc.

% Update optimValues
optimValues = objectiveSenseManager.updateOptimValues(optimValues);

% Call output functions
stop_outputfcns = matlab.internal.optimfun.utils.callAllOptimOutputFcns(outputfcns,x,optimValues,state,varargin{:});

% Call plot functions
stop_plotfcns = matlab.internal.optimfun.utils.callAllOptimPlotFcns(plotfcns,x,optimValues,state,varargin{:});

% Check stop
stop = stop_outputfcns || stop_plotfcns;
end
