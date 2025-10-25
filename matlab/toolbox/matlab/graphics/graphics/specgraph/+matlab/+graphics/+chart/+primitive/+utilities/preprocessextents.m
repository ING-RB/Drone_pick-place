function [ varargout ] = preprocessextents(varargin )
% PREPROCESSEXTENTS removes nonfinite data
%     OUT = PREPROCESSEXTENTS(IN)
%     Removes non finite data from input vector, IN.
%
%     [VARARGOUT] = PREPROCESSEXTENTS(IN)
%     If input is an array, removes entire row of data if any element is
%     nonfinite and returns each column independently in varargout, etc.
%     If number of output arguments is more than the number of input
%     columns, a scalar 0 will be reported for all remaining outputs.
%
%     [VARARGOUT] = PREPROCESSEXTENTS(IN1,IN2,IN3,...)
%     Multiple column vectors of equal height can be provide as separate
%     input arguments. If any element of a vector is non-finite, the
%     corresponding row is removed from all vectors before they are
%     returned in varargout.

%   Copyright 2012-2020 The MathWorks, Inc.

if nargin == 1
    isFiniteMatrix = isfinite(varargin{1});
    
     % Treat 0x0 as a true empty column, but treat 0xN like other matrices.
    trueEmptyCols = all(size(varargin{1}) == 0); 
    emptyVecCols = false; % This is ignored in the single input case.
else
    isFiniteMatrix = true(size(varargin{1},1),nargin);
    
     % For compatibility, we handle 0x0 inputs (true empty) differently
     % from 0x1 inputs (empty column vectors).
    trueEmptyCols = false(1,nargin);
    emptyVecCols = false(1,nargin);
    for n = 1:nargin
        if all(size(varargin{n}) == 0)
            trueEmptyCols(n) = true;
        elseif isempty(varargin{n})
            emptyVecCols(n) = true;
        else
            isFiniteMatrix(:,n) = isfinite(varargin{n});
        end
    end
end

finiteRowInds = all(isFiniteMatrix,2);
allfinite = all(finiteRowInds);

varargout = cell(nargout,1);
if nargin == 1 && ~trueEmptyCols && nargout > 1
    % In the single input case, if multiple outputs are requested the
    % columns of the input are returned as separate outputs.
    mat = varargin{1};
    if ~allfinite
        mat = mat(finiteRowInds,:);
    end
    for n = 1:size(mat,2)
        varargout{n} = mat(:,n);
    end
    extraOutputsStart = size(mat,2)+1;
else
    % Otherwise, return the processed version of the input to nargout.
    for n = 1:nargin
        if nargin > 1 && (trueEmptyCols(n) || (emptyVecCols(n) && ~all(emptyVecCols|trueEmptyCols))) 
            % The compatible behavior where 0 is returned should only occur
            % in the case where there are multiple inputs and either:
            % (1) the current input is a 0x0 true empty; or
            % (2) the current input is a 0x1 empty vector, but there are 
            %     some non-empty inputs also.
            varargout{n} = 0;
        else
            if allfinite
                varargout{n} = varargin{n};
            else
                varargout{n} = varargin{n}(finiteRowInds,:);
            end
        end
    end
    extraOutputsStart = nargin+1;
end

% Extra outputs requested will be returned as scalar zero.
if nargout >= extraOutputsStart
    for n = extraOutputsStart:nargout
        varargout{n} = 0;
    end
end
end