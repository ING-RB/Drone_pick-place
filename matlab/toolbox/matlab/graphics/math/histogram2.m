function h = histogram2(varargin)
% Syntax
%     histogram2(X,Y)
%     histogram2(X,Y,NBINS)
%     histogram2(X,Y,XEDGES,YEDGES)
%     histogram2(XBinEdges=XEDGES,YBinEdges=YEDGES,BinCounts=COUNTS)
%
%     histogram2(___,Name=Value)
%     histogram2(AX,___)
%     H = histogram2(___)
%
%     Name-Value Arguments:
%         BinWidth
%         XBinLimits
%         YBinLimits
%         BinMethod
%         ShowEmptyBins
%         Normalization
%         DisplayStyle
%
% The properties listed here are only a subset. For full list of Histogram2
% Properties and more information, see documentation

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.graphics.internal.*;
[cax,args] = axescheck(varargin{:});
% Check whether the first input is an axes input, which would have been
% stripped by the axescheck function
firstaxesinput = (rem(length(varargin) - length(args),2) == 1);
if length(args)>=2  && ~isCharOrString(args{1}) && ~isCharOrString(args{2})
    varxName = inputname(1+firstaxesinput);
    varyName = inputname(2+firstaxesinput);
else
    varxName = '';
    varyName = '';
end

[opts,args,vectorinput] = parseinput(args, firstaxesinput);

cax = newplot(cax);

[~,autocolor] = matlab.graphics.chart.internal.nextstyle(cax,true,false,true);
% lighten the autocolor
autocolor = hsv2rgb(min(rgb2hsv(autocolor).*[1 1 1.25],1));
optscell = binspec2cell(opts); 
hObj = matlab.graphics.chart.primitive.Histogram2('Parent', cax, ...
    'AutoColor', autocolor, optscell{:}, args{:});

% enable linking
hlink = hggetbehavior(hObj,'Linked');
hlink.DataSourceFcn = {@(hObj,data)set(hObj,'Data',[data{1}(:), data{2}(:)])};

hlink.UsesXDataSource = true;
hlink.UsesYDataSource = true;
% Only enable linking if the data is a vector and BinCounts not specified. 
% Brushing behavior is designed for vector data and does not work well 
% with matrix data
hasinputnames = ~isempty(varxName) && ~isempty(varyName); 
if hasinputnames && vectorinput && isempty(opts.BinCounts)
    hlink.XDataSource = varxName;
    hlink.YDataSource = varyName;
end
if isempty(get(hObj,'DisplayName')) && hasinputnames
    hObj.DisplayName = [varyName, ' vs. ' varxName];
end

% disable basic fit, and data statistics, but enable linked brushing
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
if ~isempty(ancestor(hObj, 'axes'))
    hdatadescriptor = hggetbehavior(hObj,'DataDescriptor');
    hdatadescriptor.Enable = false;
    hdatadescriptor.Serialize = true;
end

if ismember(cax.NextPlot, {'replace','replaceall'})
    cax.Box = 'on';
    grid(cax,'on');
    axis(cax,'tight');
end

if ~strcmp(hObj.DisplayStyle, 'tile') && ~strcmp(cax.NextPlot,'add')
    view(cax,3);
end

% If applying to a linked plot the linked plot graphics cache must
% be updated manually since there are not yet eventmanager listeners
% to do this automatically.
f = ancestor(hObj,'figure');
if ~isempty(f) && ~isempty(f.findprop('LinkPlot')) && f.LinkPlot
    datamanager.updateLinkedGraphics(f);
end

    hObj.assignSeriesIndex();

if nargout > 0
    h = hObj;
end
end

function [opts,passthrough,isvectorinput] = parseinput(input, inputoffset)

import matlab.graphics.internal.*;
opts = struct('Data',[],'NumBins',[],'BinMethod','auto','BinWidth',[],...
    'XBinLimits',[],'YBinLimits',[],'XBinEdges',[],'YBinEdges',[],...
    'Normalization','','BinCounts',[]);
% mode properties variables for error checking
xbinlimitsmode = [];
ybinlimitsmode = [];
bincountsmode = [];
funcname = mfilename;
passthrough = {};
isvectorinput = false;

% Parse first and second inputs
if ~isempty(input)
    x = input{1};
    if ~isCharOrString(x)
        if isscalar(input)
            error(message('MATLAB:histogram2:MissingYInput'));
        end
        y = input{2};
        input(1:2) = [];
        validateattributes(x,{'numeric','logical'},{'real'}, funcname, ...
            'x', inputoffset+1)
        validateattributes(y,{'numeric','logical'},{'real','size',size(x)}, ...
            funcname, 'y', inputoffset+2)
        opts.Data = [x(:) y(:)];
        isvectorinput = isvector(x);
        inputoffset = inputoffset + 2;
    end

    % Parse third and fourth inputs in the function call
    if ~isempty(input)
        in = input{1};
        if ~isCharOrString(in)
            inputlen = length(input);
            if inputlen == 1 || ~(isnumeric(input{2}) || islogical(input{2}))
                if isscalar(in)
                    in = [in in];
                end
                validateattributes(in,{'numeric','logical'},{'integer', 'positive', ...
                    'numel', 2, 'vector'}, funcname, 'm', inputoffset+1)
                opts.NumBins = in;
                input(1) = [];
                inputoffset = inputoffset + 1;
            else
                in2 = input{2};
                validateattributes(in,{'numeric','logical'},{'vector', ...
                    'real', 'nondecreasing'}, funcname, 'xedges', inputoffset+1)
                if length(in) < 2
                    error(message('MATLAB:histogram2:EmptyOrScalarXBinEdges'));
                end
                validateattributes(in2,{'numeric','logical'},{'vector','nonempty', ...
                    'real', 'nondecreasing'}, funcname, 'yedges', inputoffset+2)
                if length(in2) < 2
                    error(message('MATLAB:histogram2:EmptyOrScalarYBinEdges'));
                end
                opts.XBinEdges = in;
                opts.YBinEdges = in2;
                input(1:2) = [];
                inputoffset = inputoffset + 2;
            end
            opts.BinMethod = [];
        end
        
        % All the rest are name-value pairs
        inputlen = length(input);
        if rem(inputlen,2) ~= 0
            error(message('MATLAB:histogram2:ArgNameValueMismatch'))
        end
        
        % compile the list of all settable property names, filtering out the
        % read-only properties
        names = setdiff(properties('matlab.graphics.chart.primitive.Histogram2'),...
            {'Children','Values','Type','Annotation','BeingDeleted'});
        
        for i = 1:2:inputlen
            name = validatestring(input{i},names);
            
            value = input{i+1};
            switch name
                case 'Data'
                    validateattributes(value,{'numeric','logical'},...
                        {'real','ncols',2}, funcname, 'Data', i+1+inputoffset)
                    opts.Data = value;
                case 'NumBins'
                    if isscalar(value)
                        value = [value value]; %#ok
                    end
                    validateattributes(value,{'numeric','logical'},{'integer',...
                        'positive','numel',2,'vector'}, funcname, 'NumBins', i+1+inputoffset)
                    opts.NumBins = value;
                    if ~isempty(opts.XBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedXBinInputs'))
                    elseif ~isempty(opts.YBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedYBinInputs'))
                    end
                    opts.BinMethod = [];
                    opts.BinWidth = [];
                case 'XBinEdges'
                    validateattributes(value,{'numeric','logical'},{'vector', ...
                        'real', 'nondecreasing'}, funcname, 'XBinEdges', i+1+inputoffset);
                    if length(value) < 2
                        error(message('MATLAB:histogram2:EmptyOrScalarXBinEdges'));
                    end
                    opts.XBinEdges = value;
                    % Only set NumBins field to empty if both XBinEdges and
                    % YBinEdges are set, to enable BinEdges override of one
                    % dimension
                    if ~isempty(opts.YBinEdges)
                        opts.NumBins = [];
                        opts.BinMethod = [];
                        opts.BinWidth = [];
                    end
                    opts.XBinLimits = [];
                case 'YBinEdges'
                    validateattributes(value,{'numeric','logical'},{'vector', ...
                        'real', 'nondecreasing'}, funcname, 'YBinEdges', i+1+inputoffset);
                    if length(value) < 2
                        error(message('MATLAB:histogram2:EmptyOrScalarYBinEdges'));
                    end
                    opts.YBinEdges = value;
                    % Only set NumBins field to empty if both XBinEdges and
                    % YBinEdges are set, to enable BinEdges override of one
                    % dimension
                    if ~isempty(opts.XBinEdges)
                        opts.BinMethod = [];
                        opts.BinWidth = [];
                        opts.NumBins = [];
                    end
                    opts.YBinLimits = [];
                case 'BinWidth'
                    if isscalar(value)
                        value = [value value]; %#ok
                    end
                    validateattributes(value, {'numeric','logical'}, {'real',...
                        'positive', 'finite','numel',2, 'vector'}, funcname, ...
                        'BinWidth', i+1+inputoffset);
                    opts.BinWidth = value;
                    if ~isempty(opts.XBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedXBinInputs'))
                    elseif ~isempty(opts.YBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedYBinInputs'))
                    end
                    opts.BinMethod = [];
                    opts.NumBins = [];
                case 'XBinLimits'
                    validateattributes(value, {'numeric','logical'}, {'numel', 2, 'vector', ...
                        'real', 'finite','nondecreasing'}, funcname, 'XBinLimits', ...
                        i+1+inputoffset)
                    opts.XBinLimits = value;
                    if ~isempty(opts.XBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedXBinInputs'))
                    end
                case 'YBinLimits'
                    validateattributes(value, {'numeric','logical'}, {'numel', 2, 'vector',...
                        'real', 'finite','nondecreasing'}, funcname, 'YBinLimits', ...
                        i+1+inputoffset)
                    opts.YBinLimits = value;
                    if ~isempty(opts.YBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedYBinInputs'))
                    end
                case 'BinMethod'
                    opts.BinMethod = validatestring(value, {'auto','scott', 'fd', ...
                        'integers'}, funcname, 'BinMethod', i+1+inputoffset);
                    if ~isempty(opts.XBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedXBinInputs'))
                    elseif ~isempty(opts.YBinEdges)
                        error(message('MATLAB:histogram2:InvalidMixedYBinInputs'))
                    end
                    opts.BinWidth = [];
                    opts.NumBins = [];
                case 'Normalization'
                    opts.Normalization = validatestring(value, {'count', 'countdensity', 'cumcount',...
                        'probability', 'percentage', 'pdf', 'cdf'}, funcname, 'Normalization', i+1+inputoffset);
                case 'BinCounts'
                    validateattributes(value,{'numeric','logical'},{'real', ...
                        '2d','nonnegative','finite'}, funcname, 'BinCounts', i+1+inputoffset)
                    opts.BinCounts = value;
                case 'XBinLimitsMode'
                    xbinlimitsmode = validatestring(value, {'auto', 'manual'});
                case 'YBinLimitsMode'
                    ybinlimitsmode = validatestring(value, {'auto', 'manual'});
                case 'BinCountsMode'
                    bincountsmode = validatestring(value, {'auto', 'manual'});
                otherwise
                    % all other options are passed directly to the object
                    % constructor, making sure we pass in the full property names
                    passthrough = [passthrough {name} input(i+1)]; %#ok<AGROW>
            end
        end
        % error checking about consistency between properties
        if ~isempty(xbinlimitsmode)
            if strcmp(xbinlimitsmode, 'auto')
                if ~isempty(opts.XBinEdges) || ~isempty(opts.XBinLimits)
                    error(message('MATLAB:histogram2:NonEmptyXBinLimitsAutoMode'));
                end
            else  % manual
                if isempty(opts.XBinEdges) && isempty(opts.XBinLimits)
                    error(message('MATLAB:histogram2:EmptyXBinLimitsManualMode'));
                end
            end
            passthrough = [passthrough {'XBinLimitsMode' xbinlimitsmode}];
        end
        if ~isempty(ybinlimitsmode)
            if strcmp(ybinlimitsmode, 'auto')
                if ~isempty(opts.YBinEdges) || ~isempty(opts.YBinLimits)
                    error(message('MATLAB:histogram2:NonEmptyYBinLimitsAutoMode'));
                end
            else  % manual
                if isempty(opts.YBinEdges) && isempty(opts.YBinLimits)
                    error(message('MATLAB:histogram2:EmptyYBinLimitsManualMode'));
                end
            end
            passthrough = [passthrough {'YBinLimitsMode' ybinlimitsmode}];
        end
        if ~isempty(bincountsmode)
            if strcmp(bincountsmode, 'auto')
                if ~isempty(opts.BinCounts)
                    error(message('MATLAB:histogram2:NonEmptyBinCountsAutoMode'));
                end
            else  % manual
                if isempty(opts.BinCounts)
                    error(message('MATLAB:histogram2:EmptyBinCountsManualMode'));
                end
            end
            passthrough = [passthrough {'BinCountsMode' bincountsmode}];            
        end
        if ~isempty(opts.BinCounts)
            if (length(opts.XBinEdges) ~= size(opts.BinCounts,1)+1 || ...
                length(opts.YBinEdges) ~= size(opts.BinCounts,2)+1)
                error(message('MATLAB:histogram2:BinCountsInvalidSize'))
            end
            if ~isempty(opts.Data)
                error(message('MATLAB:histogram2:MixedDataBinCounts'))
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

xbinedges = hObj.XBinEdges;
ybinedges = hObj.YBinEdges;
if ~isvector(I) && ~isempty(I) 
    I = I(:,1);
end
Iout = histcounts2(hObj.Data(logical(I),1), hObj.Data(logical(I),2), xbinedges, ybinedges);
if hObj.Brushed && any(strcmp(hObj.Normalization, {'cumcount', 'cdf'}))
    % Special code for brushing cumulative histograms, highlight the entire
    % bar
    Iout = hObj.Values .* sign(Iout);
else
    switch hObj.Normalization
        case 'countdensity'
            binarea = bsxfun(@times,double(diff(xbinedges.')),...
                double(diff(ybinedges)));
            Iout = Iout./binarea;
        case 'cumcount'
            Iout = cumsum(cumsum(Iout,1),2);
        case 'probability'
            total = sum(all(bsxfun(@ge, hObj.Data, ...
                [hObj.XBinLimits(1) hObj.YBinLimits(1)]),2) & ...
                all(bsxfun(@le, hObj.Data, [hObj.XBinLimits(2) hObj.YBinLimits(2)]),2));
            Iout = Iout/total;
        case 'pdf'
            total = sum(all(bsxfun(@ge, hObj.Data, ...
                [hObj.XBinLimits(1) hObj.YBinLimits(1)]),2) & ...
                all(bsxfun(@le, hObj.Data, [hObj.XBinLimits(2) hObj.YBinLimits(2)]),2));
            binarea = bsxfun(@times,double(diff(xbinedges.')),...
                double(diff(ybinedges)));
            Iout = Iout/total./binarea;
        case 'cdf'
            total = sum(all(bsxfun(@ge, hObj.Data, ...
                [hObj.XBinLimits(1) hObj.YBinLimits(1)]),2) & ...
                all(bsxfun(@le, hObj.Data ,[hObj.XBinLimits(2) hObj.YBinLimits(2)]),2));
            Iout = cumsum(cumsum(Iout/total,1),2);
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
        % only write to non-zero bins, to avoid overwriting brushed empty
        % cumulative bins
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
