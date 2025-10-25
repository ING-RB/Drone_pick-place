function cp = comparisonPlot(baseline, measurement, sampleStat, namedArgs)
% COMPARISONPLOT - Generate a plot to compare the measured times of TimeResult arrays.
%
%   cp = comparisonPlot(baseline, measurement) generates a ComparisonPlot object
%   based on the minimum of the sample measured times of TimeResult object 
%   arrays baseline and measurement.
%
%   cp = comparisonPlot(baseline, measurement, sampleStat) generates a 
%   ComparisonPlot object by specifying the sample statistic that is
%   applied to the sample measurement times of each TimeResult object.
%   To specify the statistic, set sampleStat to 'min', 'max', 'mean', or 'median'.
%
%   cp = comparisonPlot( ___, NAME, VALUE) generates a ComparisonPlot 
%   object with additional options specified by one or more Name-Value 
%   pair arguments. The method supports the following named arguments.
%   
%   -'Scale' specifies the scale of plot axes and can be set to 'log' or 
%    'linear'.
%
%   -'SimilarityTolerance' is a number within [0,1) that specifies the  
%    border region between the faster and slower regions of the ComparisonPlot 
%    object. If the relative difference between the sample statistics of 
%    two TimeResult objects falls inside of the border region, the 
%    corresponding data point is marked as similar. Otherwise, it is 
%    marked as either faster or slower.
%
%   -'Parent' is the parent container of the plot, specified as a figure, 
%    panel, or tab object.

% Copyright 2018-2019 The MathWorks, Inc.

arguments
    baseline {validateMeasurementResult}
    measurement {validateMeasurementResult}
    sampleStat (1,1) string {mustBeMember(sampleStat, {'min', 'max', 'mean', 'median'})} = 'min'
    namedArgs.Scale (1,1) string {mustBeMember(namedArgs.Scale, {'log', 'linear'})} = 'log'
    namedArgs.SimilarityTolerance (1,1) double {validateSimilarityTolerance} = 0.1
    namedArgs.Parent {validateParent} = gcf
end

parent = namedArgs.Parent;
scale = namedArgs.Scale;
tolerance = namedArgs.SimilarityTolerance;

% Compare the size of result arrays, after split by labels
baseline = baseline.splitByLabels;
measurement = measurement.splitByLabels;

if numel(baseline) ~= numel(measurement)
    error(message('MATLAB:unittest:performance:TimeResult:SizeNotComparable'));
end

% Change stats input to function handle
statFunc = str2func(sampleStat);

function out = safestat(X)
N = length(X);
if N == 0
    out = NaN;
else
    out = statFunc(X);
end
end

% Extract faster/slower labels
slowerLabel = getString(message('MATLAB:unittest:performance:TimeResult:SlowerLabel'));
fasterLabel = getString(message('MATLAB:unittest:performance:TimeResult:FasterLabel'));

% Prepare data to plot
R1Data = samplefun(@safestat, baseline);
R2Data = samplefun(@safestat, measurement);
R1Names = arrayfun(@(r, l)appendLabelToName(r, l), baseline, [baseline.LabelList]);
R2Names = arrayfun(@(r, l)appendLabelToName(r, l), measurement, [measurement.LabelList]);

% Filter out unplottable data (NaN, negative, etc)
iBadResult = (R1Data <= 0) | isnan(R1Data) | (R2Data <= 0) | isnan(R2Data);
iResult2Plot = ~iBadResult;

% Warn about unplottable data
if any(iBadResult)
    name1_filter = R1Names(iBadResult);
    data1_filter = R1Data(iBadResult);
    name2_filter = R2Names(iBadResult);
    data2_filter = R2Data(iBadResult);
    warn_msg = '';
    for i = 1:numel(name1_filter)
        warn_msg = [warn_msg ...
            sprintf('%s: %s, %s: %s \n', ...
            char(name1_filter(i)), num2str(data1_filter(i)), ...
            char(name2_filter(i)), num2str(data2_filter(i)))];
    end
    warning(message('MATLAB:unittest:performance:TimeResult:BadData', warn_msg));
end

baseline = baseline(iResult2Plot);
measurement = measurement(iResult2Plot);
R1Data = R1Data(iResult2Plot);
R2Data = R2Data(iResult2Plot);
R1Names = R1Names(iResult2Plot);
R2Names = R2Names(iResult2Plot);

% Construct the ComparisonPlot.
constructor = @(varargin)matlab.unittest.measurement.chart.ComparisonPlot(...
    slowerLabel, fasterLabel, varargin{:});
try
    cp = matlab.graphics.internal.prepareCoordinateSystem(...
        'matlab.unittest.measurement.chart.ComparisonPlot', ...
        parent, constructor);
catch e
    throw(e)
end

% Append Unit to Axes Labels
UnitStr = getString(message('MATLAB:unittest:performance:TimeResult:Unit'));
cp.BaselineLabel = [cp.BaselineLabel, ' ', UnitStr];
cp.MeasurementLabel = [cp.MeasurementLabel, ' ', UnitStr];

cp.Scale = scale;
cp.SimilarityTolerance = tolerance;
cp.BaselineData = R1Data; 
cp.MeasurementData = R2Data;
cp.Valid = [baseline.Valid] & [measurement.Valid];
cp.BaselineDataNames = string(R1Names);
cp.MeasurementDataNames = string(R2Names);
updateTitle(cp, sampleStat);
if ~isempty([cp.Valid]) && all([cp.Valid])
    addTitleSummary(cp);
end
legend(cp);
end

function updateTitle(chart, stat)
chart.TitleLabel = {getString(message('MATLAB:unittest:performance:TimeResult:ComparisonPlotTitle',stat))};
end

function addTitleSummary(chart)
s = chart.OverallStat;
overallstat = strtrim(sprintf('%3.0f', abs(s)*100));
if s >= 0
    chart.TitleLabel(end + 1) = {getString(message('MATLAB:unittest:performance:TimeResult:TitleOverallSlower', overallstat))};
else
    chart.TitleLabel(end + 1) = {getString(message('MATLAB:unittest:performance:TimeResult:TitleOverallFaster', overallstat))};
end
end

% Input Validators
function validateMeasurementResult(input)
validateattributes(input, {'matlab.perftest.TimeResult', ...
    'matlab.unittest.measurement.DefaultMeasurementResult'}, {});
end

function validateSimilarityTolerance(input)
validateattributes(input, {'numeric'}, {'scalar', 'nonnan', 'nonnegative', '<', 1});
end

function validateParent(parent)
validateattributes(parent, {'matlab.graphics.Graphics'}, {'scalar'});
if ~isvalid(parent)
    % Parent cannot be a deleted graphics object.
    throwAsCaller(MException(message('MATLAB:unittest:performance:TimeResult:DeletedParent')));
elseif isa(parent,'matlab.graphics.axis.AbstractAxes')
    % ComparisonPlot cannot be a child of Axes.
    throwAsCaller(MException(message('MATLAB:hg:InvalidParent',...
        'ComparisonPlot', fliplr(strtok(fliplr(class(parent)), '.')))));
end
end