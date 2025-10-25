function [x,var] = checkSamplePoints(x,A,AisTable,AisTimeTable,dim)
%checkSamplePoints Validate SamplePoints value
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2017 - 2023 The MathWorks, Inc.

if isempty(A)
    if (isnumeric(x) || isduration(x) || isdatetime(x)) && ~isempty(x)
        if ~(AisTable || AisTimeTable)&& ~isequal(size(A,dim),numel(x))
            error(message('MATLAB:samplePoints:SamplePointsLength',size(A,dim)));
        elseif AisTable && ~(numel(x) <= width(A) && all(x > 0) && all(mod(x,1) == 0))
            error(message('MATLAB:samplePoints:SamplePointsTableSubscript'));
        end
        var = [];
        return;
    end
end
if AisTimeTable
    tname = 'Row times';
else
    tname = '''SamplePoints''';
end
var = [];
%% Check Sample Points table varspec
% if x is numeric, duration, or datetime vector, treat x as explicit sample points
% if A has one row and x is a numeric scalar, treat x as explicit sample points
% if x is logical, treat x as a varspec
if AisTable && (~((isnumeric(x) || isduration(x) || isdatetime(x)) && ~isscalar(x)) && ...
        ~(isequal(size(A,1),1) && isnumeric(x) && isscalar(x)) ||...
        islogical(x))
    if isa(x,'function_handle')
        nvars = width(A);
        try
            bData = cell(1,nvars);
            for j = 1:nvars
                bData{j} = x(A{:,j});
            end
        catch ME
            error(message('MATLAB:samplePoints:SamplePointsFunctionHandle'));
        end
        if nvars > 0
            for jvar = 1:nvars
                if ~isscalar(bData{jvar})
                    error(message('MATLAB:samplePoints:SamplePointsFunctionHandle'));
                elseif jvar == 1
                    uniformClass = class(bData{1});
                elseif ~isa(bData{jvar},uniformClass)
                    error(message('MATLAB:samplePoints:SamplePointsFunctionHandle'));
                end
            end
            bData = horzcat(bData{:});
        else
            bData = zeros(1,0);
        end
        if sum(bData) ~= 1
            error(message('MATLAB:samplePoints:SamplePointsTableSubscript'));
        end
        var = find(bData);
        x = A.(var);
    else
        try
            var = subscripts2indices(A,x,'reference','varDim');
        catch ME
            error(message('MATLAB:samplePoints:SamplePointsTableSubscript'));
        end
        if ~isscalar(var)
            error(message('MATLAB:samplePoints:SamplePointsTableSubscript'));
        end
        x = A.(var);
    end
end
%% Check Sample Points
if AisTimeTable && isempty(A)
    return
end
if (~isvector(x) && ~isempty(x)) || ...
        (~isnumeric(x) && ~isduration(x) && ~isdatetime(x))
    error(message('MATLAB:samplePoints:SamplePointsInvalidDatatype'));
end
if numel(x) ~= (size(A,dim) * ~isempty(A))
    error(message('MATLAB:samplePoints:SamplePointsLength',size(A,dim)));
end
x = x(:);
if isfloat(x)
    if ~isreal(x)
        error(message('MATLAB:samplePoints:SamplePointsComplex'));
    end
    if issparse(x)
        error(message('MATLAB:samplePoints:SamplePointsSparse'));
    end
end
if (isfloat(x) || isduration(x)) && ~allfinite(x)
    error(message('MATLAB:samplePoints:SamplePointsNonFinite',tname,'NaN'));
end
if isdatetime(x) && ~allfinite(x)
    error(message('MATLAB:samplePoints:SamplePointsNonFinite',tname,'NaT'));
end
if any(diff(x) <= 0)
    if any(diff(x) == 0)
        error(message('MATLAB:samplePoints:SamplePointsDuplicate',tname));
    else
        error(message('MATLAB:samplePoints:SamplePointsSorted',tname));
    end
end
