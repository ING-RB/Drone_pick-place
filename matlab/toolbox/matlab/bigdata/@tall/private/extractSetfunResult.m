function varargout = extractSetfunResult(t, varargin)
% EXTRACTSETFUNRESULT Extract the results from setfunCommon in T and apply
% the logic required for a particular set function.
%
% C = EXTRACTSETFUNRESULT(T,CONDITIONFCN) extracts the results in T to
% produce the final answer for a particular set function with CONDITIONFCN.
% CONDITIONFCN is a function handle that takes indices IA and IB and
% generates a tall logical index.
%
% [C,IA,IB] = EXTRACTSETFUNRESULT(T,CONDITIONFCN) returns C, IA, and IB
% from T according to the condition in CONDITIONFCN. CONDITIONFCN is a
% function handle that takes indices IA and IB and generates a tall logical
% index.
%
% [C,IA,IB] = EXTRACTSETFUNRESULT(T) extracts all the elements in C, IA,
% and IB from table T.

%   Copyright 2019 The MathWorks, Inc.

narginchk(1, 2);
nargoutchk(1, 3);

isConditionProvided = false;
if nargin > 1
    conditionFcn = varargin{1};
    isConditionProvided = true;
end

% Extract data from the common implementation of set functions
c = subsref(t, substruct('.', 'C'));
ia = subsref(t, substruct('.', 'indA'));
ib = subsref(t, substruct('.', 'indB'));

if isConditionProvided
    % Apply the logic for the set function as given by conditionFcn
    idx = conditionFcn(ia, ib);
    
    % Filter slices for output C
    varargout{1} = filterslices(idx, c);
    
    % Filter slices for indices if requested
    if nargout > 1
        varargout{2} = filterslices(idx, ia);
        if nargout > 2
            varargout{3} = filterslices(idx, ib);
        end
    end
else
    varargout{1} = c;
    if nargout > 1
        varargout{2} = ia;
        if nargout > 2
            varargout{3} = ib;
        end
    end
end
end