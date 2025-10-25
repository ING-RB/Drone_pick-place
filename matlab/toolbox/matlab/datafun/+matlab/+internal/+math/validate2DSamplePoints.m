function validate2DSamplePoints(A,samplePoints,window)
%validate2DSamplePoints Validate sample points for 2D functions
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023 The MathWorks, Inc.

if ~iscell(samplePoints) || numel(samplePoints) ~= 2
    error(message("MATLAB:gridded2DData:SPTwoElementCellArray"));
end
if ~(isvector(samplePoints{1}) || isempty(samplePoints{1})) || ...
        ~(isvector(samplePoints{2}) || isempty(samplePoints{2}))
    error(message("MATLAB:gridded2DData:SPMustBeVectors"));
end

% Size is also checked by checkSamplePoints. Duplicate size checks are to
% provide useful error messages.
if numel(samplePoints{1}) ~= size(A,1)
    error(message("MATLAB:gridded2DData:SPWrongSize",1,size(A,1)));
end
if numel(samplePoints{2}) ~= size(A,2)
    error(message("MATLAB:gridded2DData:SPWrongSize",2,size(A,2)));
end

AIsTable = false;
AIsTimetable = false;
matlab.internal.math.checkSamplePoints(samplePoints{1},A,AIsTable,AIsTimetable,1);
matlab.internal.math.checkSamplePoints(samplePoints{2},A,AIsTable,AIsTimetable,2);

if nargin == 3 % for moving window methods
    if iscell(window)
        if ~spAndWindowTypesMatch(samplePoints{1},window{1})
            error(message("MATLAB:gridded2DData:SpTypeDoesntMatchWindow",1));
        end
        if ~spAndWindowTypesMatch(samplePoints{2},window{2})
            error(message("MATLAB:gridded2DData:SpTypeDoesntMatchWindow",2));
        end
    else
        if ~spAndWindowTypesMatch(samplePoints{1},window)
            error(message("MATLAB:gridded2DData:SpTypeDoesntMatchWindow",1));
        end
        if ~spAndWindowTypesMatch(samplePoints{2},window)
            error(message("MATLAB:gridded2DData:SpTypeDoesntMatchWindow",2));
        end
    end
end
end

function tf = spAndWindowTypesMatch(sp,window)
    tf = (isnumeric(sp) && isnumeric(window)) || (isduration(window) && (isdatetime(sp) || isduration(sp)));
end