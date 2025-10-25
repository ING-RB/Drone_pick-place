function out = invokeOutputInfo(fcnInfo, out, inputArgs)
%invokeOutputInfo Applies known information to an output

% Copyright 2016-2022 The MathWorks, Inc.

if isstruct(fcnInfo)
    % We have the full fcnInfo array. Extract the output type and table
    % recursion flags.
    outType = fcnInfo.OutputType;
    recurseIntoTables = fcnInfo.AllowTabularMaths;
else
    % We have been given the output type directly.
    outType = fcnInfo;
    recurseIntoTables = false;
end

if ~isempty(outType)
    outAdaptor = iDetermineOutputAdaptor(fcnInfo.Name, recurseIntoTables, outType, inputArgs{:});
    % Copy the adaptor we calculated into the output, preserving the
    % output size.
    out.Adaptor = copySizeInformation(outAdaptor, out.Adaptor);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outAdaptor = iDetermineOutputAdaptor(methodName, recurseIntoTables, typeRule, varargin)
% Determine the output adaptor for a given set of inputs and the specified
% type-rule. If the type rule names a type directly (e.g. "logical") we
% simply apply the adaptor for that type directly, ignoring the input
% types.

if recurseIntoTables && any(cellfun(@istabular, varargin))
    % Use the standard helper to traverse the table, looking at the
    % variable types instead.
    outAdaptor = determineAdaptorForTabularMath( ...
        @(varargin) iDetermineOutputAdaptor(methodName, recurseIntoTables, typeRule, varargin{:}), ...
        methodName, varargin{:});
else
    % Non-tabular or not recursing, so determine thee type using one of our
    % rules.
    switch typeRule
        case 'preserve'
            outType = iGetInTypeFromArgs(varargin);
        case 'preserveLogicalCharToDouble'
            outType = iGetInTypeFromArgs(varargin);
            if ismember(outType, {'logical', 'char'})
                outType = 'double';
            end
        case 'binaryArithmeticRule'
            assert(numel(varargin) <= 2);
            inClassNames = cellfun(@tall.getClass, varargin, 'UniformOutput', false);
            if isscalar(inClassNames)
                inClassNames = [inClassNames, inClassNames];
            end
            outType = calculateArithmeticOutputType(inClassNames{:});
        otherwise
            % A type was specified by name. Create the adaptor directly.
            outType = typeRule;
    end
    outAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(outType);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function inType = iGetInTypeFromArgs(inCell)

adaptors = cellfun(@matlab.bigdata.internal.adaptors.getAdaptor, ...
    inCell, 'UniformOutput', false);
inTypes  = unique(cellfun(@(ad) ad.Class, adaptors, 'UniformOutput', false));

% Note that if some of the arguments have unknown types, then we cannot
% deduce the output type, since that type might be superior to one of the
% known types. In particular, imagine combining a tall array containing
% single (but this information is lost) with a host-scalar-double. In that
% case, the output type is single - but we cannot know that.

if isscalar(inTypes)
    inType = inTypes{1};
else
    % Here we are imbuing this function with some knowledge about superiority of
    % types. Specifically, duration is superior to all other types when
    % combined, and double is inferior.
    inTypes = setdiff(inTypes, {'double'});
    if isscalar(inTypes)
        % double + something else, return the something else. This might cause problems
        % later it turned out that the non-double was the scalar, and the double
        % was an array. E.g. tall(rand(3)) + uint8(1)
        inType = inTypes{1};
    elseif ismember(inTypes, {'duration'})
        inType = 'duration';
    else
        % Hm, trouble. uint8+uint16 or similar. Return ''.
        inType = '';
    end
end
end
