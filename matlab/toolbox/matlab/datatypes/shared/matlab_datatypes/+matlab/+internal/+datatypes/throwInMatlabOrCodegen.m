function throwInMatlabOrCodegen(id, varargin) %#codegen
%THROWINMATLABORCODEGEN Throw a MException with the specified ID in MATLAB or codegen.
%   THROWINMATLABORCODEGEN(ID)
%   THROWINMATLABORCODEGEN(ID,...,'MessageArgs',{...})
%   THROWINMATLABORCODEGEN(ID,...,'Correction',{correctionType,correctionArgs})
%
%   Example:
%     THROWINMATLABORCODEGEN(ID,'Correction',{'ReplaceIdentifierCorrection','oldFunc','newFunc'});

%   Copyright 2020-2021 The MathWorks, Inc.

    assert(mod(nargin-1,2)==0); % there should always be an even number of extra arguments
    idxMsgArgs = find(strcmpi(varargin,'MessageArgs'));
    if any(idxMsgArgs)
        messageArgs = varargin{idxMsgArgs+1};
    else
        messageArgs = cell(1,0);
    end
    idxCorrect = find(strcmpi(varargin,'Correction'));
    if any(idxCorrect)
        correction = varargin{idxCorrect+1};
    end
    coder.internal.assert(coder.target('MATLAB'),id,messageArgs{:});
    ME = MException(message(id,messageArgs{:}));
    if any(idxCorrect)
        correctionType = correction{1};
        correctionArgs = correction(2:end);
        correction = feval(strcat('matlab.lang.correction.',correctionType),correctionArgs{:});
        ME = addCorrection(ME,correction);
    end
    throwAsCaller(ME);
end
