function h = histogram(varargin)
% Syntax:
%     histogram(X)
%     histogram(X,NBINS)
%     histogram(X,EDGES)
%     histogram(BinEdges=EDGES,BinCounts=COUNTS)
%
%     histogram(C)
%     histogram(C,CATEGORIES)
%     histogram(Categories=CATEGORIES,BinCounts=COUNTS)
%
%     histogram(___,Name=Value)
%     histogram(AX,___)
%     H = histogram(___)
%
%     Name-Value Arguments:
%         BinWidth
%         BinLimits
%         BinMethod
%         DisplayOrder
%         NumDisplayBins
%         ShowOthers
%         Normalization
%         DisplayStyle
%         Orientation
%         BarWidth
%
% The properties listed here are only a subset. For full list of Histogram
% Properties and more information, see documentation

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.internal.isCharOrString
import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes

supportDoubleAxesHandle = true;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

% If peelFirstArgParent detected the first input argument was the parent
% (and removed it), update the index numbers for the remaining inputs.
firstaxesinput = numel(args) < numel(varargin);
if ~isempty(args) && ~isCharOrString(args{1})
    varName = inputname(1+firstaxesinput);
else
    varName = '';
end

[opts,passthrough,dispatchToCategorical] = parseinput(args,firstaxesinput);
if dispatchToCategorical
    try
        % histogram('Categories', ..., 'BinCounts', ...) syntax
        % Dispatch to categorical method
        hObj = categoricalHistogram(categorical.empty, args, parent);
        
        % Use hint framework to disable brushing for categorical histograms
        setInteractionHint(hObj, 'DataBrushing', false);
        
    catch ME % hide categoricalHistogram stack
        throw(ME);
    end
else
    [parent, hasParent] = getParent(parent, passthrough);
    [parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent);
    
    if isscalar(ancestorAxes)
        [~,opts.AutoColor] = matlab.graphics.chart.internal.nextstyle(ancestorAxes,true,false,true);
    end

    optscell = binspec2cell(opts);
    x = opts.Data;
    if isempty(x) && ~isempty(opts.BinCounts)
        x = opts.BinEdges;
    end

    % configure axes for datetime/duration
    if isscalar(ancestorAxes)
        if strcmp(opts.Orientation, 'horizontal') || ...
                (isempty(opts.Orientation) && strcmp(get(parent, 'defaultHistogramOrientation'), 'horizontal'))
            if isa(ancestorAxes, 'matlab.graphics.axis.PolarAxes')
                error(message('MATLAB:histogram:UnsupportedOrientationInPolarCoordinates'));
            end
            matlab.graphics.internal.configureAxes(ancestorAxes,1,x);
        else
            matlab.graphics.internal.configureAxes(ancestorAxes,x,1);
        end
    end

    hObj = matlab.graphics.chart.primitive.Histogram('Parent', parent, ...
        optscell{:}, passthrough{:});
    
    % enable linking
    hlink = hggetbehavior(hObj,'Linked');
    hlink.DataSourceFcn = {@(hObj,data)set(hObj,'Data',data{1})};
    hlink.UsesYDataSource = true;
    % Only enable linking if the data is a vector and BinCounts not specified.
    % Brushing behavior is designed for vector data and does not work well
    % with matrix data
    if ~isempty(varName) && isvector(opts.Data) && isempty(opts.BinCounts)
        hlink.YDataSource = varName;
    end
    if isempty(get(hObj,'DisplayName'))
        hObj.DisplayName_I = hlink.YDataSource;
    end
    
    % disable brushing, basic fit, and data statistics, but enable
    % linked brushing
    hlink.BrushFcn = {@localLinkedBrushFunc};
    hlink.LinkBrushQueryFcn = {@(~,region,hObj)hObj.getBrushedElements(region);};
    hlink.LinkBrushUpdateIFcn = {@(~,I,Iextend,~,extendMode,hObj)...
        hObj.updatePartiallyBrushedI(I,Iextend,extendMode);};
    hlink.LinkBrushUpdateObjFcn = {@(~,region,lastregion,hObj)...
        hObj.updateBrushedGraphic(region,lastregion);};
    hlink.Serialize = true;
    hbrush = hggetbehavior(hObj,'brush');
    hbrush.Serialize = true;
    hbrush.DrawFcn = {@localDrawFunc};
    if ~isempty(ancestor(hObj, 'matlab.graphics.axis.AbstractAxes','node'))
        hdatadescriptor = hggetbehavior(hObj,'DataDescriptor');
        hdatadescriptor.Enable = false;
        hdatadescriptor.Serialize = true;
    end
    
    switch nextplot
        case {'replaceall','replace'}
            ancestorAxes.Box = 'on';
            matlab.graphics.internal.setRulerLayerTop(ancestorAxes);
        case 'replacechildren'
            matlab.graphics.internal.setRulerLayerTop(ancestorAxes);
    end
    
    % If applying to a linked plot the linked plot graphics cache must
    % be updated manually since there are not yet eventmanager listeners
    % to do this automatically.
    f = ancestor(hObj,'figure');
    if ~isempty(f) && ~isempty(f.findprop('LinkPlot')) && f.LinkPlot
        datamanager.updateLinkedGraphics(f);
    end
    
end

hObj.assignSeriesIndex();

if nargout > 0
    h = hObj;
end

end

function [opts,passthrough,dispatchToCategorical] = parseinput(input,inputoffset)

import matlab.graphics.internal.*;
opts = struct('Data',[],'NumBins',[],'BinEdges',[],'BinLimits',[],...
    'BinWidth',[],'Normalization','','BinMethod','auto','BinCounts',[], ...
    'Orientation', '');
% mode properties variables for error checking
binlimitsmode = [];
bincountsmode = [];
funcname = mfilename;
passthrough = {};
allnamevalues = true;
dispatchToCategorical = false;
for i = 1:length(input)
    dispatchToCategorical = isa(input{i}, 'categorical');
    if dispatchToCategorical, return; end
end

% Parse first input
if ~isempty(input)
    x = input{1};
    if ~isCharOrString(x)
        input(1) = [];
        % list categorical here so error message is correct
        % categorical inputs shouldn't actually get here
        validateattributes(x,{'numeric','logical','datetime','duration','categorical'},...
            {'real'}, funcname, 'x', inputoffset+1)
        opts.Data = x;
        inputoffset = inputoffset + 1;
        allnamevalues = false;
    end
    
    % Parse second input in the function call
    if ~isempty(input)
        in = input{1};
        if ~isCharOrString(in)
            if isscalar(in)
                validateattributes(in,{'numeric','logical'},{'integer', 'positive'}, ...
                    funcname, 'm', inputoffset+1)
                opts.NumBins = in;
                opts.BinMethod = '';
            else
                if isdatetime(opts.Data)
                    if ~isdatetime(in) || ~isvector(in) || isempty(in)
                        error(message('MATLAB:histogram:InvalidDatetimeEdges'));
                    elseif ~issorted(in) || any(isnat(in))
                        error(message('MATLAB:histogram:UnsortedDatetimeEdges'));
                    end
                elseif isduration(opts.Data)
                    if ~isduration(in) || ~isvector(in) || isempty(in)
                        error(message('MATLAB:histogram:InvalidDurationEdges'));
                    elseif ~issorted(in) || any(isnan(in))
                        error(message('MATLAB:histogram:UnsortedDurationEdges'));
                    end
                else  % numeric or logical
                    validateattributes(in,{'numeric','logical'},{'vector','nonempty', ...
                        'real', 'nondecreasing'}, funcname, 'edges', inputoffset+1)
                end
                    
                opts.BinEdges = in;
                opts.BinMethod = '';
            end
            input(1) = [];
            inputoffset = inputoffset + 1;
        end
        
        % All the rest are name-value pairs
        if rem(length(input),2) ~= 0
            error(message('MATLAB:histogram:ArgNameValueMismatch'))
        end
        
        % compile the list of all settable property names, filtering out the
        % read-only properties
        names = [setdiff(properties('matlab.graphics.chart.primitive.Histogram'),...
            {'Children','Values','Type','Annotation','BeingDeleted'}); {'Categories'}];
        inputlen = length(input);
        for i = 1:2:inputlen
            
            name = validatestring(input{i},names);
            
            value = input{i+1};
            switch name
                case 'Data'
                    validateattributes(value,{'numeric','logical',...
                        'datetime','duration'},{'real'}, ...
                        funcname, 'Data', i+1+inputoffset)
                    opts.Data = value;
                case 'NumBins'
                    validateattributes(value,{'numeric','logical'},{'scalar', ...
                        'integer', 'positive'}, funcname, 'NumBins', i+1+inputoffset)
                    opts.NumBins = value;
                    if ~isempty(opts.BinEdges)
                        error(message('MATLAB:histogram:InvalidMixedBinInputs'))
                    end
                    opts.BinMethod = '';
                    opts.BinWidth = [];
                case 'BinEdges'
                    if isdatetime(value) 
                        if ~isvector(value)
                            error(message('MATLAB:histogram:InvalidDatetimeEdges'));
                        elseif ~issorted(value) || any(isnat(value))
                            error(message('MATLAB:histogram:UnsortedDatetimeEdges'));
                        end
                    elseif isduration(value)
                        if ~isvector(value)
                            error(message('MATLAB:histogram:InvalidDurationEdges'));
                        elseif ~issorted(value) || any(isnan(value))
                            error(message('MATLAB:histogram:UnsortedDurationEdges'));
                        end
                    else  % numeric or logical
                        validateattributes(value,{'numeric','logical'},{'vector',...
                            'real', 'nondecreasing'}, funcname, 'edges', inputoffset+1)
                    end
                    if length(value) < 2
                        error(message('MATLAB:histogram:EmptyOrScalarBinEdges'));
                    end
                    opts.BinEdges = value;
                    opts.BinMethod = '';
                    opts.BinWidth = [];
                    opts.NumBins = [];
                    opts.BinLimits = [];
                case 'BinWidth'
                    if isduration(value)
                        if ~(isscalar(value) && isfinite(value) && value > 0)
                            error(message('MATLAB:histogram:InvalidBinWidth'));
                        end
                    elseif iscalendarduration(value)
                        if ~(isscalar(value) && isfinite(value))
                            error(message('MATLAB:histogram:InvalidBinWidth'));
                        end
                        [caly,calm,cald,calt] = split(value,{'year','month','day','time'});
                        if (caly < 0 || calm < 0 || cald < 0 || calt < 0) || ...
                                (caly == 0 && calm == 0 && cald == 0 && calt == 0)
                            error(message('MATLAB:histogram:InvalidBinWidth'));
                        end
                    else % numeric or logical
                        validateattributes(value, {'numeric','logical'}, {'scalar', 'real', ...
                            'positive', 'finite'}, funcname, 'BinWidth', i+1+inputoffset);
                    end
                    opts.BinWidth = value;
                    if ~isempty(opts.BinEdges)
                        error(message('MATLAB:histogram:InvalidMixedBinInputs'))
                    end
                    opts.BinMethod = '';
                    opts.NumBins = [];
                case 'BinLimits'
                    if isdatetime(value) || isduration(value)
                        if ~(numel(value)==2 && issorted(value) && all(isfinite(value)))
                            error(message('MATLAB:histogram:InvalidDatetimeOrDurationBinLimits',...
                                class(value)));
                        end
                    else 
                    validateattributes(value, {'numeric','logical'}, {'numel', 2, 'vector', 'real', ...
                        'nondecreasing', 'finite'}, funcname, 'BinLimits', i+1+inputoffset)
                    end
                    opts.BinLimits = value;
                    if ~isempty(opts.BinEdges)
                        error(message('MATLAB:histogram:InvalidMixedBinInputs'))
                    end
                case 'Normalization'
                    opts.Normalization = validatestring(value, {'count', 'countdensity', 'cumcount',...
                        'probability','percentage', 'pdf', 'cdf'}, funcname, 'Normalization', i+1+inputoffset);
                case 'BinMethod'
                    opts.BinMethod = validatestring(value, {'auto','scott', 'fd', ...
                            'integers', 'sturges', 'sqrt', 'century', 'decade', 'year', ...
                            'quarter', 'month', 'week', 'day', 'hour', 'minute', ...
                            'second'}, funcname, 'BinMethod', i+1+inputoffset);                  
                    if ~isempty(opts.BinEdges)
                        error(message('MATLAB:histogram:InvalidMixedBinInputs'))
                    end
                    opts.BinWidth = [];
                    opts.NumBins = [];
                case 'BinCounts'
                    validateattributes(value,{'numeric','logical'},{'real', ...
                        'vector','nonnegative','finite'}, funcname, 'BinCounts', i+1+inputoffset)
                    opts.BinCounts = reshape(value,1,[]);  % ensure row
                case 'BinLimitsMode'
                    binlimitsmode = validatestring(value, {'auto', 'manual'});
                case 'BinCountsMode'
                    bincountsmode = validatestring(value, {'auto', 'manual'});
                case 'Categories'
                    if allnamevalues
                        % histogram('Categories', ..., 'BinCounts', ...)
                        % syntax. Dispatch to categorical method.
                        dispatchToCategorical = true;
                        return
                    else
                        error(message('MATLAB:histogram:UnsupportedCategories'));
                    end
                case 'Orientation'
                    opts.Orientation = validatestring(value, {'vertical', 'horizontal'}, ...
                        funcname, 'Orientation', i+1+inputoffset);
                otherwise
                    % all other options are passed directly to the object
                    % constructor, making sure we pass in the full property names
                    passthrough = [passthrough {name} input(i+1)]; %#ok<AGROW>
            end
        end
        % error checking about consistency between properties
        if ~isempty(binlimitsmode)
            if strcmp(binlimitsmode, 'auto')
                if ~isempty(opts.BinEdges) || ~isempty(opts.BinLimits)
                    error(message('MATLAB:histogram:NonEmptyBinLimitsAutoMode'));
                end
            else  % manual
                if isempty(opts.BinEdges) && isempty(opts.BinLimits)
                    error(message('MATLAB:histogram:EmptyBinLimitsManualMode'));
                end
            end
            passthrough = [passthrough {'BinLimitsMode' binlimitsmode}];
        end
        if ~isempty(bincountsmode)
            if strcmp(bincountsmode, 'auto')
                if ~isempty(opts.BinCounts)
                    error(message('MATLAB:histogram:NonEmptyBinCountsAutoMode'));
                end
            else  % manual
                if isempty(opts.BinCounts)
                    error(message('MATLAB:histogram:EmptyBinCountsManualMode'));
                end
            end
            passthrough = [passthrough {'BinCountsMode' bincountsmode}];            
        end
        if ~isempty(opts.BinCounts)
            if length(opts.BinEdges) ~= length(opts.BinCounts)+1
                error(message('MATLAB:histogram:BinCountsInvalidSize'))
            end
            if ~isempty(opts.Data)
                error(message('MATLAB:histogram:MixedDataBinCounts'))
            end
            if (isdatetime(opts.BinEdges) || isduration(opts.BinEdges)) && ...
                    ismember(opts.Normalization, {'countdensity', 'pdf'})
                error(message('MATLAB:histogram:DatetimeNormalization'))
            end
        else
            if isdatetime(opts.Data) || isduration(opts.Data)
                if ~isempty(opts.BinEdges) && ~isequal(class(opts.Data), class(opts.BinEdges))
                    error(message('MATLAB:histogram:DatetimeBinEdgesClass', class(opts.Data)))
                elseif ~isempty(opts.BinLimits) && ~isequal(class(opts.Data), class(opts.BinLimits))
                    error(message('MATLAB:histogram:DatetimeBinLimitsClass', class(opts.Data)))
                elseif ismember(opts.Normalization, {'countdensity', 'pdf'})
                    error(message('MATLAB:histogram:DatetimeNormalization'))
                elseif ismember(opts.BinMethod, {'integers'})
                    error(message('MATLAB:histogram:DatetimeBinMethod'))
                end
                if isdatetime(opts.Data)
                    if ~isempty(opts.BinWidth) && (isnumeric(opts.BinWidth) ...
                            || islogical(opts.BinWidth))
                        error(message('MATLAB:histogram:InvalidDatetimeBinWidth'))
                    end
                else %duration
                    if ismember(opts.BinMethod, {'century', ...
                            'decade', 'quarter', 'month', 'week'})
                        error(message('MATLAB:histogram:DurationBinMethod', opts.BinMethod))
                    end
                    if ~isempty(opts.BinWidth) && ~isduration(opts.BinWidth)
                        error(message('MATLAB:histogram:InvalidDurationBinWidth'))
                    end
                end
            else % numeric or logical data
                if isdatetime(opts.BinEdges) || isduration(opts.BinEdges)
                    error(message('MATLAB:histogram:NumericBinEdgesClass'))
                elseif isduration(opts.BinWidth) || iscalendarduration(opts.BinWidth)
                    error(message('MATLAB:histogram:NumericBinWidthClass'))
                elseif isdatetime(opts.BinLimits) || isduration(opts.BinLimits)
                    error(message('MATLAB:histogram:NumericBinLimitsClass'))
                elseif ismember(opts.BinMethod, ...
                        {'century', 'decade', 'year', 'quarter', 'month', ...
                        'week', 'day', 'hour', 'minute', 'second'})
                    error(message('MATLAB:histogram:NumericBinMethod'))
                end
            end
        end
    end
end
end

function binargs = binspec2cell(binspec)
% Construct a cell array of name-value pairs given a binspec struct
binspecn = fieldnames(binspec);  % extract field names
empties = structfun(@isempty,binspec);
binspec = rmfield(binspec,binspecn(empties));  % remove empty fields
binspecn = binspecn(~empties);
binspecv = struct2cell(binspec);
binargs = [binspecn binspecv]';
end

function brushStruct = localLinkedBrushFunc(I, hObj)

% Linked behavior object BrushFcn

% Converts variable brushing arrays (arrays of uint8 the same size as a 
% linked variable which define which subset of that variable is brushed and
% in which color) into generalized brushing data (the generalized form of 
% the BrushData property used by the brush behavior object). For histograms, 
% generalized brushing data is a struct with a field I representing the 
% height of each brushed bin and an index ColorIndex into the figure  
% BrushStyleMap representing the brushing color.

binedges = hObj.BinEdges;

if isPolar(hObj)
    minedge = min(hObj.BinEdges);
    %collapse angles to the 2pi interval that starts at the
    %lowest bin edge
    data = mod(hObj.Data(logical(I)) - minedge,2*pi)+minedge;
    Iout = histcounts(data, binedges);
else
    Iout = histcounts(hObj.Data(logical(I)), binedges);    
end
if hObj.Brushed && any(strcmp(hObj.Normalization, {'cumcount', 'cdf'}))
    % Special code for brushing cumulative histograms, highlight the entire
    % bar
    Iout = hObj.Values .* sign(Iout);
else
    switch hObj.Normalization
        case 'countdensity'
            Iout = Iout./double(diff(binedges));
        case 'cumcount'
            Iout = cumsum(Iout);
        case 'probability'
            Iout = Iout/sum(hObj.Data>=hObj.BinLimits(1) ...
                & hObj.Data<=hObj.BinLimits(2));
        case 'pdf'
            Iout = Iout/sum(hObj.Data>=hObj.BinLimits(1) ...
                & hObj.Data<=hObj.BinLimits(2))./double(diff(binedges));
        case 'cdf'
            Iout = cumsum(Iout/sum(hObj.Data>=hObj.BinLimits(1) ...
                & hObj.Data<=hObj.BinLimits(2)));
    end
end
[~,~,brushStyleMapInd] = find(I,1); 
brushStruct = struct('I',Iout,'ColorIndex',brushStyleMapInd);
end

function localDrawFunc(brushStruct,hObj)
% Uses a struct with fields I and ColorIndex to set the BrushColor and BrushValues
% properties of the histogram object
if ~isempty(brushStruct)
    if hObj.Brushed && any(strcmp(hObj.Normalization, {'cumcount', 'cdf'})) 
        nonzeroI = brushStruct.I > 0;
        hObj.BrushValues(nonzeroI) = brushStruct.I(nonzeroI);
    else
        hObj.BrushValues = brushStruct.I;
    end
    if isfield(brushStruct, 'ColorIndex') && ~isempty(brushStruct.ColorIndex)
        fig = ancestor(hObj,'figure');
        brushStyleMap = get(fig,'BrushStyleMap');
        hObj.BrushColor = brushStyleMap(rem(brushStruct.ColorIndex-1,...
            size(brushStyleMap,1))+1,:);
    end
end
end
