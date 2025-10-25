%CategoricalAdaptor Adaptor class for categorical data
%   Adapts subsasgn to allow tc(tc=='foo') = 'bar';
%   and disallows flags to MIN/MAX.

% Copyright 2016-2023 The MathWorks, Inc.
classdef CategoricalAdaptor < ...
        matlab.bigdata.internal.adaptors.AbstractAdaptor & ...
        matlab.bigdata.internal.adaptors.GeneralArrayDisplayMixin & ...
        matlab.bigdata.internal.adaptors.GeneralArrayParenIndexingMixin & ...
        matlab.bigdata.internal.adaptors.NoCellIndexingMixin

    properties (SetAccess = immutable)
        IsOrdinal
        IsProtected
    end

    properties (Access = private)
        Categories
    end

    methods (Access = protected)
        function m = buildMetadataImpl(obj)
            m = matlab.bigdata.internal.adaptors.CategoricalMetadata(obj.TallSize);
        end
    end

    methods
        function obj = CategoricalAdaptor(example)
            obj@matlab.bigdata.internal.adaptors.AbstractAdaptor('categorical');
            if nargin>0
                obj.IsOrdinal = isordinal(example);
                obj.IsProtected = isprotected(example);
                obj.Categories = categories(example);
            else
                obj.IsOrdinal = false;
                obj.IsProtected = false;
                obj.Categories = {};
            end
        end

        function names = getProperties(~)
            names = {};
        end

        function categories = getCategories(obj)
            categories = obj.Categories;
        end

        function obj = resetCategories(obj, newCategories)
            % Delete or reset the categories set during construction of the
            % adaptor.
            if nargin > 1
                obj.Categories = cellstr(newCategories);
            else
                obj.Categories = {};
            end
        end

        function out = subsasgnParens(obj, pa, szPa, S, b)
        % For categorical SUBSASGN, if 'b' is a char-vector, wrap it in a cell before
        % calling the mixin version of SUBSASGN.
            if ischar(b)
                b = {b};
            end
            out = subsasgnParens@matlab.bigdata.internal.adaptors.GeneralArrayParenIndexingMixin(...
                obj, pa, szPa, S, b);
        end

        function [nanFlagCell, precisionFlagCell] = interpretReductionFlags(~, FCN_NAME, flags)

            % Categorical family types don't have any precision flags
            precisionFlagCell = {};
            omitFlags = {'omitnan', 'omitmissing'};
            includeFlags = {'includenan', 'includemissing'};
            if ismember(lower(FCN_NAME), {'max', 'min', 'median'})
                omitFlags = [omitFlags, {'omitundefined'}];
                includeFlags = [includeFlags, {'includeundefined'}];
            end
            otherFlags = {}; % Flags to allow through but ignore
            if ismember(lower(FCN_NAME), {'max', 'min'})
                % min/max also accept the 'linear' flag
                otherFlags = {'linear'};
            end
            parsedFlags = iParseFlags(FCN_NAME, flags, omitFlags, includeFlags, otherFlags);
            linearFlagCell = parsedFlags(ismember(parsedFlags, otherFlags));
            if numel(linearFlagCell) >= 2
                % 'linear' has been specified more than once. Only suggest
                % the remaining nan-related options.
                error(message('MATLAB:bigdata:array:InvalidRepeatedFlag', FCN_NAME, ...
                              strjoin([omitFlags, includeFlags], ', ')));
            end
            nanFlagCell = parsedFlags(ismember(parsedFlags, [omitFlags, includeFlags]));
            if ismember(lower(FCN_NAME), {'median'}) && isempty(nanFlagCell)
                % For MEDIAN we always need to provide a default NaN flag
                nanFlagCell = {'includenan'};
            elseif numel(nanFlagCell) >= 2
                error(message('MATLAB:bigdata:array:InvalidRepeatedFlag', FCN_NAME, ...
                              strjoin([omitFlags, includeFlags, otherFlags], ', ')));
            end
        end
    end

    methods (Access = protected)
        % Build a sample of the underlying data.
        function sample = buildSampleImpl(obj, ~, sz, ~)
            % Always use missing as sample, categories must match with the
            % input data.
            sample = repmat(categorical(missing, 'Protected', obj.IsProtected, 'Ordinal', obj.IsOrdinal), sz);
            if ~isempty(obj.Categories)
                sample = setcats(sample, obj.Categories);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse omit/include flags (and linear flag for min/max).
function parsedflags = iParseFlags(FCN_NAME, flags, omitFlags, includeFlags, otherFlags)
parsedflags = cell(1, numel(flags));
for idx = 1:numel(flags)
    thisFlag = flags{idx};
    n = numel(thisFlag);
    if n > 0 && any(strncmpi(thisFlag, omitFlags, n))
        parsedflags{idx} = 'omitnan';
    elseif n > 0 && any(strncmpi(thisFlag, includeFlags, n))
        parsedflags{idx} = 'includenan';
    elseif n > 0 && any(strncmpi(thisFlag, otherFlags, n)) && ismember(lower(FCN_NAME), {'max', 'min'})
        parsedflags{idx} = 'linear';
    else
        validFlagsStr = strjoin([omitFlags, includeFlags, otherFlags], ', ');
        error(message('MATLAB:bigdata:array:InvalidOption', thisFlag, FCN_NAME, validFlagsStr));
    end
end
end
