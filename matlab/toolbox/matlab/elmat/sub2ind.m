function ndx = sub2ind(siz,v1,v2,varargin)
%SUB2IND Linear index from multiple subscripts.
%   SUB2IND is used to determine the equivalent single index
%   corresponding to a given set of subscript values.
%
%   IND = SUB2IND(SIZ,I,J) returns the linear index equivalent to the
%   row and column subscripts in the arrays I and J for a matrix of
%   size SIZ.
%
%   IND = SUB2IND(SIZ,I1,I2,...,IN) returns the linear index
%   equivalent to the N subscripts in the arrays I1,I2,...,IN for an
%   array of size SIZ.
%
%   I1,I2,...,IN must have the same size, and IND will have the same size
%   as I1,I2,...,IN. For an array A, if IND = SUB2IND(SIZE(A),I1,...,IN)),
%   then A(IND(k))=A(I1(k),...,IN(k)) for all k.
%
%   Class support for inputs I,J:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also IND2SUB.

%   Copyright 1984-2023 The MathWorks, Inc.

siz = double(siz);
lensiz = numel(siz);
if ~isreal(siz) || ~isvector(siz) || lensiz < 2
    error(message('MATLAB:sub2ind:InvalidSize'));
end

numOfIndInput = nargin-1;
if numOfIndInput > 0
    % Adjust siz if needed
    if lensiz < numOfIndInput
        % Adjust for trailing singleton dimensions
        siz = [siz, ones(1,numOfIndInput-lensiz)];
    elseif lensiz > numOfIndInput
        % Adjust for linear indexing on last element
        siz = [siz(1:numOfIndInput-1), prod(siz(numOfIndInput:end))];
    end
    % Check index arguments
    set_size = false;
    for i = 1:numOfIndInput
        if i == 1
            v = v1;
        elseif i == 2
            v = v2;
        else
            ind = i-2;
            v = varargin{ind};
        end
        if ~set_size
            if ~isscalar(v)
                s = size(v);
                set_size = true;
            end
        else
            if ~isscalar(v) && ~isequal(s,size(v))
                % Verify sizes of subscripts
                error(message('MATLAB:sub2ind:SubscriptVectorSize'));
            end
        end
        if ~isreal(v)
            % Verify subscripts are real
            error(message('MATLAB:sub2ind:RealSubscript'));
        end
        siz_i = siz(i);
        if ~isempty(v) && (anynan(v) || min(v,[],'all') < 1 || max(v,[],'all') > siz_i)
            % Verify subscripts are within range
            error(message('MATLAB:sub2ind:IndexOutOfRange'));
        end
    end
end

% Compute linear indices
if numOfIndInput <= 1
    ndx = double(v1);
else
    k = siz(1);
    ndx = double(v1) + (double(v2)-1)*k;
    k = k * siz(2);
    for i = 3:numOfIndInput
        ind = i-2;
        ndx = ndx + (double(varargin{ind})-1)*k;
        k = k * siz(i);
    end
end
