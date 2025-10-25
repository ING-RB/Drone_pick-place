function b = mean(a,dim,option1,option2) %#codegen
%MEAN Mean of datetimes.

%   Copyright 2020 The MathWorks, Inc.

needDim = true;
omitnan = false;

if nargin > 1
    % Recognize DIM if present as the 2nd input, and recognize any trailing string
    % options if present.
    if isnumeric(dim) % mean(a,dim,...)
        coder.internal.assert(matlab.internal.coder.datatypes.isValidDimArg(dim),'MATLAB:datetime:InvalidVecDim');
        needDim = false;
        dimProcessed = dim;
        nopts = nargin - 2;
        aProcessed = a;
        
        if nopts > 0
            option1Processed = option1;
            if nopts > 1
                option2Processed = option2;
            end
        end
        
    elseif matlab.internal.coder.datatypes.isScalarText(dim) % 'all' or options
        if strncmpi(dim,'all',max(strlength(dim),1))
            needDim = false;
            aProcessed = reshape(a,[],1);
            dimProcessed = 1;
            
            
            nopts = nargin - 2;
            
            if nopts > 0
                option1Processed = option1;
                if nopts > 1
                    option2Processed = option2;
                end
            end
            
        elseif nargin < 4
            nopts = nargin - 1;
            if nopts == 1 % mean(a,option1)
                % OK
            else % mean(a,option1,option2)
                option2Processed = option1; % 2nd option string is in 1st option's position
            end
            option1Processed = dim; % 1st option string is in dim's position
            aProcessed = a;
        elseif nargin == 4
            option1Processed = option1;
            option2Processed = option2;
            aProcessed = a;
            dimProcessed = dim;
        else % not numeric dim or 'all'
            coder.internal.assert(false,'MATLAB:datetime:InvalidVecDim');
        end
    else
        coder.internal.assert(false,'MATLAB:datetime:InvalidVecDim');
    end
    
    % Validate the options strings.
    if nopts > 0
        if nopts > 1
            omitnan = validateMissingOptionLocal({option1Processed,option2Processed},omitnan,needDim);
        else
            omitnan = validateMissingOptionLocal({option1Processed},omitnan,needDim);
        end
    end
else
    aProcessed = a;
end

b = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
b.fmt = a.fmt;
b.tz = a.tz;
if needDim
    dimProcessed = coder.internal.nonSingletonDim(a.data);
end


if (coder.internal.isConst(isempty(a)) && isempty(a))
    
    if omitnan
        nanFlag = 'omitnan';
    else
        nanFlag = 'includenan';
    end
    
    if needDim
        [templateData] = mean(aProcessed.data,nanFlag);
    else
        [templateData] = mean(aProcessed.data,dimProcessed,nanFlag);
    end
    
    b = datetime.fromMillis(complex(templateData),a.fmt);
    return
end

needsReshape = false;
if ~all(dimProcessed ==1) && (~isempty(aProcessed.data))
    [aData,szOut] = permuteWorkingDims(aProcessed.data,dimProcessed);
    needsReshape = true;
else
    aData = aProcessed.data;
    szOut = size(aData);
end


bData = matlab.internal.coder.datetime.datetimeMean(aData,1,omitnan);
if needsReshape
    b.data = reshape(bData,szOut);
else
    b.data = bData;
end

%-----------------------------------------------------------------------
function [omitnan,haveOption] = validateMissingOptionLocal(options,omitnan,includeAll)
% Accept 'include/omitmissing' (and their nat/nan versions), and accept
% 'default' and 'native' (ultimately these are no-ops), but error for 'double'.
% Only accept one from each set.

% haveOption tracks how many of each missing and type options have been found
% already, to catch things like mean(x,'omitnan','includenan').
haveOption = zeros(1,2); % missing flags and type flags, respectively

if nargin < 3
    % includeAll determines if 'all' should be included in the error
    % message or not
    includeAll = false;
end

possibleFlags   = {'omitmissing' 'omitnan', 'omitnat', 'includemissing' 'includenan' ,'includenat', 'double', 'default', 'native'};
possibleOptions = [ 1,            1,         1,         2,               2,             2,            3,       4,         4      ];
for i = 1:numel(options)
    option = options{i};
    if includeAll
        choiceNum = matlab.internal.coder.datatypes.getChoice(option,possibleFlags,possibleOptions,'MATLAB:datetime:UnknownMeanOptionAllFlag');
    else
        choiceNum = matlab.internal.coder.datatypes.getChoice(option,possibleFlags,possibleOptions,'MATLAB:datetime:UnknownMeanOption');
    end
    
    coder.internal.errorIf(choiceNum == 3, 'MATLAB:datetime:InvalidNumericConversion',option); % 'double', an errors
    
    if choiceNum == 1 || choiceNum == 2
        haveOption(1) = haveOption(1) + 1; % this was a missing flag
    else
        haveOption(2) = haveOption(2) + 1; % this was a type flag
    end
    
    if choiceNum == 1
        omitnan = true;
    end
end

% Make sure this is the first time that option has been seen.
coder.internal.errorIf((haveOption(1) > 1 || haveOption(2) > 1 ),'MATLAB:datetime:UnknownMeanOption');

