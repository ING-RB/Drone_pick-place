function varargout = sharedplotfunc(fname,inputvals)
%PLOTPICKERFUNC  Support function for Plot Picker component.

% Copyright 2009-2019 The MathWorks, Inc.

% Default display functions for shared toolbox plots

n = length(inputvals);
toshow = false;
switch lower(fname)
    case {'highlow','candle'}
        numVars = 4;
        names = {'open','high','low','close'};
        optionalCheck = {{'Color'},{''},{@(x)1,@ischar}};
        if n == 1 || n == 2
            toshow = checkFinancialChartingInput(inputvals,numVars,names,optionalCheck);
        end
    case 'kagi'
        numVars = 1;
        names = {'price'};
        if n == 1
            toshow = checkFinancialChartingInput(inputvals,numVars,names);
        end
        if toshow
            tmpData = inputvals{1};
            if istable(tmpData) || istimetable(tmpData)
                tmpData = table2array(tmpData);
            end
            if issorted(tmpData,'monotonic')
               toshow = false; 
            end
        end
    case 'pointfig'
        numVars = 1;
        names = {'price'};
        if n == 1
            toshow = checkFinancialChartingInput(inputvals,numVars,names);
        end
        if toshow
            if numel(inputvals{1}) == 1
                toshow = false;
            end
        end
    case 'renko'
        numVars = 1;
        names = {'price'};
        thresholdValidate = @(x) validateattributes(x,{'numeric'}, {'scalar'},'','Threshold');
        optionalCheck = {{'Threshold'},{1},{thresholdValidate}};
        if n == 1 || n == 2
            toshow = checkFinancialChartingInput(inputvals,numVars,names,optionalCheck);
        end
        if toshow
            if numel(inputvals{1}) == 1
                toshow = false;
            end
        end
    case 'priceandvol'
        numVars = 5;
        names = {'open','high','low','close','volume'};
        if n == 1
            toshow = checkFinancialChartingInput(inputvals,numVars,names);
        end
    case 'volarea'
        numVars = 2;
        names = {'price','volume'};
        if n == 1
            toshow = checkFinancialChartingInput(inputvals,numVars,names);
        end
end
varargout{1} = toshow;

end

function financialChartCheck = checkFinancialChartingInput(args,numVars,names,varargin)
% Check the input for financial charting functions
% numVars -  the number variables necessary for the plot. For
% timetable/table case, the number of variables in the input could be
% greater than the numVars.
% names - the names that a table/timetable needs to have in order to
% extract out data properly.
try
    if isempty(varargin)
        loc_ftseriesInputParser(args, ...
            numVars,names,{},{},{},{},{},1);
    else
        loc_ftseriesInputParser(args, ...
            numVars,names,{},{},varargin{:}{:},1);
    end
catch
    financialChartCheck = false;
    return;
end

data = args{1};
if isnumeric(data)
    % Edge case: remove the support for old syntax for plotting.
    financialChartCheck = (size(data,2) == numVars);
else
    financialChartCheck = true;
end

end

function output = loc_ftseriesInputParser(rawInput, ...
    requiredDataSize, requiredDataName, ...
    requiredOtherName, requiredOtherValidate, ...
    optionalName, optionalDefault,optionalNameValidate, timeRequired)
% An internal function to parse the input for financial charting
% functions and technical indicator functions.

% Last output indicates the datatype.
% 0: matrix
% 1: table
% 2: timetable

% Supported data input type.
validateattributes(rawInput{1},{'double','timetable','table'},{});

if isVectorPattern(class(rawInput{1}),size(rawInput{1},2), ...
        requiredDataSize)
    % Only Vector input, no N-V pairs, optional input would be positional inputs.
    output = LocalParserVectorOld(rawInput,requiredDataSize, ...
        requiredOtherName,requiredOtherValidate,optionalName,optionalDefault, ...
        optionalNameValidate,timeRequired);
else
    % New case with N-V pair and new datatype input support.
    % Backward compatibility support: temporarily support positional optional
    % inputs as well.
    output =  LocalParserPackedNew(rawInput, ...
        requiredDataSize,requiredDataName,requiredOtherName, ...
        requiredOtherValidate,optionalName,optionalDefault,optionalNameValidate, ...
        timeRequired);
end

validateData(output{1},requiredDataName);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Level I: General Parser Definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = LocalParserVectorOld(args,requiredDataSize, ...
    requiredOtherName,requiredOtherValidate,optionalName,optionalDefault, ...
    optionalNameValidate,timeRequired)
% Old interface parser, designed for vector input.

% Step1: data Extraction and dates Preparation.
len = size(args{1},1);
% Must know the exact number of columns
data = zeros(len,requiredDataSize);
try
    for i = 1:requiredDataSize
        data(:,i) = args{i};
    end
catch ME
    if strcmp(ME.identifier,'MATLAB:subsassigndimmismatch')
        rethrow(ME)
    elseif strcmp(ME.identifier,'MATLAB:badsubscript')
        error(message('finance:internal:finance:ftseriesInputParser:IncorrectColNum'))
    end
end
dates = LocalDefaultDates(size(data,1),timeRequired);

warning(message('finance:internal:finance:ftseriesInputParser:SyntaxDeprecation'))

% Step2: Parsing Other Inputs
toParse = args((i+1):end);
parseResults = LocalOtherParser(toParse,requiredOtherName, ...
    requiredOtherValidate,optionalName,optionalDefault,optionalNameValidate);

% Step3: Packing
% doubles output for sure, we explicitly indicating the output type.
output = {data,parseResults,dates,0};

end

function output = LocalParserPackedNew(args, ...
    requiredDataSize,requiredDataName, ...
    requiredOtherName,requiredOtherValidate, ...
    optionalName,optionalDefault,optionalNameValidate,timeRequired)
% Parser for the new function interface.

% Step1: Data Extraction
[data, dates, datatype] = LocalNewDataParser(args{1}, ...
    requiredDataName,requiredDataSize,timeRequired);

% Step2: Parsing Other Inputs
toParse = args(2:end);
parseResults = LocalOtherParser(toParse,requiredOtherName, ...
    requiredOtherValidate, ...
    optionalName,optionalDefault,optionalNameValidate);

% Step3: Packing
output = {data,parseResults,dates,datatype};

end

function [data,dates,datatype] = LocalNewDataParser(rawData, ...
    requiredDataName,requiredDataSize,timeRequired)
% Parse the data from the new function interface, throw out warnings for
% old syntax case.

switch string(class(rawData))
    case "table"
        % Backward incompatibility due to old table support pattern.
        data = nestedExtractor();
        dates = LocalDefaultDates(size(rawData,1),timeRequired);
        datatype = 1; % table
        
    case "timetable"
        dates = rawData.Properties.RowTimes;
        % Only handle datetime as time index case. No pre-clean step for
        % duration/calendarduration case.
        if isdatetime(dates)
            nonMissingDates = rmmissing(dates);
            uniqueDates = unique(nonMissingDates);
            if (length(uniqueDates) < length(dates)) || ~(isequal(uniqueDates,dates))
                warning(message('finance:internal:finance:ftseriesInputParser:PreCleaned'))
                rawData = retime(rawData,uniqueDates);
                dates = uniqueDates;
            end
        end
        data = nestedExtractor();
		
        datatype = 2; % timetable
        
    case "double"
        if isempty(requiredDataSize)
            % no requirement for the columns of data.
            data = rawData;
            dates = LocalDefaultDates(size(rawData,1),timeRequired);
        else
            switch size(rawData,2)
                case requiredDataSize
                    data = rawData;
                    dates = LocalDefaultDates(size(rawData,1),timeRequired);
                case (requiredDataSize + 1)  % Assume an extra column for date.
                    data = rawData(:,2:end);
                    try
                        dates = rawData(:,1);
                        test = datetime(dates, 'ConvertFrom', 'datenum');
                        if timeRequired
                            dates = test;
                        end
                    catch
                        error(message('finance:internal:finance:ftseriesInputParser:IncorrectColNum'))
                    end
                    warning(message('finance:internal:finance:ftseriesInputParser:SyntaxDeprecation'))
                otherwise
                    error(message('finance:internal:finance:ftseriesInputParser:IncorrectColNum'))
            end
        end
        datatype = 0; % double
end

    function data = nestedExtractor()
        if isempty(requiredDataName)
            % Directly select out all data, require timetable to hold only
            % numeric values.
            data = rawData.Variables;
            
            if ~isempty(requiredDataSize)
                validateattributes(data,{'double'},{'size',[nan,requiredDataSize]})
            end
        else
            rawData.Properties.VariableNames = lower(rawData.Properties.VariableNames);
            missingVariables = setdiff(requiredDataName,rawData.Properties.VariableNames);
            if ~isempty(missingVariables)
                wordInQuote = @(x) ['''',x,''''];
                missingVariables = cellfun(wordInQuote,missingVariables,'UniformOutput',false);
                if numel(missingVariables) == 1
                    error(message('finance:internal:finance:ftseriesInputParser:MissingVariables', ...
                        missingVariables{:}));
                else
                    missingVariables = strjoin(missingVariables,', ');
                    error(message('finance:internal:finance:ftseriesInputParser:MissingVariables', ...
                        missingVariables));
                end
            end
            data = rawData{:,requiredDataName};
        end
    end
end

function parseResults = LocalOtherParser(toParse,requiredOtherName, ...
    requiredOtherValidate,optionalName,optionalDefault,optionalNameValidate)
% Parse the optional positional inputs for the old interface.

if isempty(requiredOtherName) && isempty(optionalName) && ~isempty(toParse)
    error(message('finance:internal:finance:ftseriesInputParser:IncorrectColNum'))
end

p = inputParser;

if ~isempty(requiredOtherName)
    for iter = 1:length(requiredOtherName)
        addRequired(p,requiredOtherName{iter},requiredOtherValidate{iter});
    end
end

% Check whether is the old positional style
% Find optional key words.
validate = @(x) ~iscell(x) && ((isvector(x) && ischar(x)) || isscalar(x)) ...
    && any(strcmpi(x,optionalName));
resultInterface = cellfun(validate,toParse);

if any(resultInterface) || length(optionalName) == 1
    newInterfaceFlag = true;
else
    newInterfaceFlag = false;
end

if newInterfaceFlag && (length(optionalName) > 1)
    % N-V pair case
    % Case: New interface
    % At least two optional input parameters.
    for iter = 1:length(optionalName)
        addParameter(p,optionalName{iter},optionalDefault{iter}, ...
            optionalNameValidate{iter});
    end
else
    % Positional input case
    % Case: Old interface & Only 1 optional input in the new interface.
    for iter = 1:length(optionalName)
        addOptional(p,optionalName{iter},optionalDefault{iter}, ...
            optionalNameValidate{iter});
    end
end

parse(p,toParse{:});
parseResults = p.Results;

if ~newInterfaceFlag && ~isempty(toParse)
    warning(message('finance:internal:finance:ftseriesInputParser:SyntaxDeprecation'))
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Level II: Utility Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flag = isVectorPattern(inputType,inputSize,requiredSize)

if (inputType == "double") && (inputSize == 1) ...
        && ~isempty(requiredSize) && (requiredSize ~= 1)
    flag = true;
else
    flag = false;
end

end

function validateData(data,names)
% Validate possible input stock prices data.

if (isempty(names))
    return;
end

OHLCV = {'open','high','low','close','volume'};
dataExtraction = false(length(OHLCV),length(names));

for iter = 1:length(OHLCV)
    dataExtraction(iter,:) = ismember(names,OHLCV{iter});
end

open = data(:,dataExtraction(1,:));
high = data(:,dataExtraction(2,:));
low = data(:,dataExtraction(3,:));
close = data(:,dataExtraction(4,:));
volume = data(:,dataExtraction(5,:));

validateattributes(open,{'numeric'},{'nonnegative'},'','Opening Price')
validateattributes(high,{'numeric'},{'nonnegative'},'','High Price')
validateattributes(low,{'numeric'},{'nonnegative'},'','Low Price')
validateattributes(close,{'numeric'},{'nonnegative'},'','Closing Price')
validateattributes(volume,{'numeric'},{'nonnegative'},'','Volume of Trades')

try
    validateattributes(double(low>high),{'numeric'},{'<',1})
catch
    warning(message('finance:internal:finance:ftseriesInputParser:InvalidPrice','Low','high'))
end

try
    validateattributes(double(open>high),{'numeric'},{'<',1})
catch
    warning(message('finance:internal:finance:ftseriesInputParser:InvalidPrice','Opening','high'))
end

try
    validateattributes(double(open<low),{'numeric'},{'<',1},'')
catch
    warning(message('finance:internal:finance:ftseriesInputParser:InvalidPrice','Low','opening'))
end

try
    validateattributes(double(close<low),{'numeric'},{'<',1},'')
catch
    warning(message('finance:internal:finance:ftseriesInputParser:InvalidPrice','Low','closing'))
end

try
    validateattributes(double(close>high),{'numeric'},{'<',1},'')
catch
    warning(message('finance:internal:finance:ftseriesInputParser:InvalidPrice','Closing','High'))
end

end

function defaultDates = LocalDefaultDates(len,timeRequired)

if timeRequired
    defaultDates = (1:len)';
else
    defaultDates = [];
end

end