function result = catUtil(dim, useSpecializedFcn, varargin)
%

%   Copyright 2021 The MathWorks, Inc.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

if ~isnumeric(dim)
    error(message('MATLAB:calendarDuration:cat:NonNumericDim'))
end

nargs = length(varargin);
m = cell(1,nargs);
d = cell(1,nargs);
ms = cell(1,nargs);
fmts = cell(1,nargs);
sz = cell(1,nargs);
template = [];
for i = 1:nargs
    arg = varargin{i};
    if isa(arg,'calendarDuration')
        if isequal(template,[])
            template = varargin{i}; % base result on first calendarDuration
        end
        components = arg.components;
        m{i} = components.months;
        d{i} = components.days;
        ms{i} = components.millis;
        fmts{i} = arg.fmt;
        sz{i} = calendarDuration.getFieldSize(components);
    elseif isa(arg,'duration')
        m{i} = 0;
        d{i} = 0;
        ms{i} = milliseconds(arg);
        fmts{i} = 'mdt';
        sz{i} = size(arg);
    elseif isa(arg,'missing')
        m{i} = 0;
        d{i} = 0;
        ms{i} = double(arg);
        fmts{i} = 'mdt';
        sz{i} = size(arg);        
    else
        % Numeric input treated as a multiple of 24 hours.
        m{i} = 0;
        d{i} = 0;
        try
            ms{i} = datenumToMillis(arg);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:calendarDuration:cat:InvalidConcatenation'));
        end
        fmts{i} = 'mdt';
        sz{i} = size(arg);
    end
end

result = template;
[result.components.months,mPlaceholders] = catComponent(useSpecializedFcn,dim,m,sz,false);
[result.components.days,dPlaceholders]   = catComponent(useSpecializedFcn,dim,d,sz,false);
% Avoid m/d/ms all ending up being collapsed to the scalar 0 placeholder,
% as that loses size information.
result.components.millis = catComponent(useSpecializedFcn,dim,ms,sz,dPlaceholders && mPlaceholders);
result.fmt = calendarDuration.combineFormats(fmts{:});


%=======================================================================
function [field,placeholder] = catComponent(useSpecializedFcn,dim,field,sz,avoidPlaceholder)
placeholders = cellfun(@(c)isequal(c,0),field);
placeholder = all(placeholders);
if placeholder && avoidPlaceholder
    % If all the arrays have a zero placeholder in this component, leave it as
    % a placeholder.
    field = 0;
else
    % Otherwise, any zero placeholders need to be expanded out to full size
    % before concatenating with non-placeholders.
    if any(placeholders)
        for i = 1:length(field)
            f = field{i};
            if isscalar(f), field{i} = repmat(f,sz{i}); end
        end
    end
    
    if useSpecializedFcn
        if dim == 1
            field = vertcat(field{:});
        elseif dim == 2
            field = horzcat(field{:});
        else
            assert(false);
        end
    else
        field = cat(dim,field{:});
    end
end