function out = combineAdaptors(dim, inCell)
%combineAdaptors Combination of adaptors for horizontal or vertical concatenation

% Copyright 2016-2023 The MathWorks, Inc.

adaptorClasses = cellfun(@class, inCell, 'UniformOutput', false);

underlyingClasses = cellfun(@(x) x.Class, inCell, 'UniformOutput', false);
isKnownUniqueUnderlyingClass = isscalar(unique(underlyingClasses)) && ...
    ~isempty(underlyingClasses{1});

isTableAdaptor     = strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.TableAdaptor');
isTimetableAdaptor = strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.TimetableAdaptor');

% Allowed combinations:
% - all 'generic' adaptors, return a plain generic adaptor
% - all DatetimeFamilyAdaptor
%   - if classes all match
%   - or duration + calendarDuration -> calendarDuration
% - datetime and char/string -> datetime
% - duration|calendarDuration and numeric -> duration|calendarDuration
% - all TableAdaptor - concatenate VariableNames and Adaptors providing VariableNames unique
% - categorical can combine with string, char, cell(str), result is always categorical
% - string combined with any generic type is string

if all(strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.GenericAdaptor'))
    out = matlab.bigdata.internal.adaptors.GenericAdaptor();
    if isKnownUniqueUnderlyingClass
        out = matlab.bigdata.internal.adaptors.getAdaptorForType(underlyingClasses{1});
    elseif ~any(underlyingClasses == "")
        inSamples = cellfun(@(a) {buildSample(resetSizeInformation(a), 'double')}, inCell);
        outSample = cat(dim, inSamples{:});
        out = matlab.bigdata.internal.adaptors.getAdaptorForType(class(outSample));
    end
    
elseif any(strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.DatetimeFamilyAdaptor'))
    % Here we still consider unknown (empty) classes
    uc = unique(underlyingClasses);
    if isscalar(uc)
        % Extract prototype of left-most adaptor, that will set up extra
        % parameters.
        proto = getPrototype(inCell{1});
        out = matlab.bigdata.internal.adaptors.DatetimeFamilyAdaptor(proto);
    else
        % We need to work out from the known-good combinations of classes.
        % Disregard unknown classes for now, treat them as if they'll work,
        % and hope for the best.
        uc(uc == "") = [];
        if isempty(setdiff(uc, { 'datetime', 'char', 'string', 'cell' }))
            outClass = "datetime";
        elseif isempty(setdiff(uc, { 'duration', 'double', 'logical' }))
            outClass = "duration";
        elseif isempty(setdiff(uc, { 'duration', 'calendarDuration', 'double', 'logical' }))
            outClass = "calendarDuration";
        else
            error(message('MATLAB:bigdata:array:InvalidConcatenation', strjoin(uc, ' ')));
        end
        adaptorsOutClass = inCell(underlyingClasses == outClass);
        % Extract prototype of left-most adaptor of the same output class.
        proto = getPrototype(adaptorsOutClass{1});
        out = matlab.bigdata.internal.adaptors.DatetimeFamilyAdaptor(proto);
    end
    
elseif all(isTableAdaptor)
    out = cat(dim, inCell{:});
    
elseif isTimetableAdaptor(1)
    if ~all(isTimetableAdaptor | isTableAdaptor)
        if dim == 1
            error(message('MATLAB:table:vertcat:TableAndTimetable'));
        else
            error(message('MATLAB:table:horzcat:TableAndTimetable'));
        end
    end
    out = cat(dim, inCell{:});
    
elseif any(isTableAdaptor) || any(isTimetableAdaptor)
    % Cannot concatenate - find the first tabular type in the argument list and use
    % that to throw an error.
    firstTabularArg   = find(isTableAdaptor | isTimetableAdaptor, 1, 'first');
    firstTabularClass = underlyingClasses{firstTabularArg};
    error(message('MATLAB:bigdata:table:InvalidTabularConcatenation', firstTabularClass));
    
elseif any(strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.CategoricalAdaptor'))
    % categorical can combine with: string, char, cell(str) - result is always categorical.
    uc = unique(underlyingClasses);
    % Remove unknown classes (which might error later)
    uc(uc == "") = [];
    % Remove known-good classes, leaving only forbidden classes
    forbiddenClasses = setdiff(uc, { 'categorical', 'string', 'char', 'cell' });
    if isempty(forbiddenClasses)
        out = matlab.bigdata.internal.adaptors.CategoricalAdaptor();
    else
        error(message('MATLAB:bigdata:array:InvalidConcatenation', strjoin(uc, ' ')));
    end
    % Now, make sure we error when we hit our limitation for combining
    % ordinal categorical arrays. We don't know categories upfront, so we
    % are unable to generate a valid combined adaptor. Do not error here if
    % we have a combination of ordinal and non-ordinal, or ordinal
    % categoricals with other datatypes. Let it throw core MATLAB error.
    categoricalAdaptors = inCell(underlyingClasses == "categorical");
    allOrdinal = all(cellfun(@(x) x.IsOrdinal, categoricalAdaptors));
    anyNonCategoricalArgs = any(uc ~= "categorical");
    if allOrdinal && ~anyNonCategoricalArgs
        error(message('MATLAB:bigdata:array:UnsupportedCategoricalConcatenation'));
    end
    
elseif any(strcmp(adaptorClasses, 'matlab.bigdata.internal.adaptors.StringAdaptor'))
    % String can combine with any generic type. Result is always string.
    out = matlab.bigdata.internal.adaptors.StringAdaptor();
    
else
    % Throw a vague error about not being able to concatenate. Should never get
    % here, as all cases should be handled above.
    error(message('MATLAB:bigdata:array:InvalidConcatenationUnknownTypes'));
    
end

% Attempt to propagate known size information by concatenating the sizes, but
% only if all small dimensions are known, and all classes are known and match
% (see g1393370 for what can happen when classes don't match - sizes can
% change!)
allNdims = cellfun(@(a) a.NDims, inCell);

if isscalar(inCell)
    out = copySizeInformation(out, inCell{1});
    
else
    % Check if we can propagate small sizes
    if ~any(isnan(allNdims)) && isKnownUniqueUnderlyingClass
        % Function to get the size from the adaptor in a vector of length
        % effectiveNdims.
        szAsCellFcn = @(a) { a.Size };
        
        % Get a cell array of all sizes
        allSizesCell = cellfun(szAsCellFcn, reshape(inCell, [], 1));
        
        % If there are any arrays that *might* be "[]", we cannot use our CAT size
        % computation, since the computation takes a completely different path for
        % those arrays.
        if ~any(cellfun(@iArrayMightBeSquareEmpty, allSizesCell))
            newSize = matlab.bigdata.internal.util.computeCatSize(dim, allSizesCell);
            out = setKnownSize(out, newSize);
        end
    end
    
    % We might be able to propagate the tall size if all inputs are the same
    % tall size and we aren't changing it, even if the small sizes are unknown.
    if dim>1 && all(cellfun(@(a) a.TallSize, inCell) == inCell{1}.TallSize)
        % Tall sizes are all the same, so output is guaranteed to also have same
        % tall size.
        out = copyTallSize(out, inCell{1});
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return TRUE if the size vector *might* correspond to a [] empty array, but it
% is not *guaranteed* to correspond to []. I.e. one of: [NaN, 0], [0, NaN],
% [NaN, NaN].
function tf = iArrayMightBeSquareEmpty(szVec)
tf = numel(szVec) == 2 && any(isnan(szVec)) && ...
     all(arrayfun(@(d) d == 0 || isnan(d), szVec));
end
