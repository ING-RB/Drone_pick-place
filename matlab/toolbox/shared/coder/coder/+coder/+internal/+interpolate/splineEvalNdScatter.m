function [v, varargout] = splineEvalNdScatter(nd, coefs, xqk, k, l, multiValIdx, varargin)

% evaluation at scattered points 
% k is order in each dimension
% l is number of pieces in each dim
% multiValIdx is used only for multi valued functions. It is used to
% iterate and treat them as seperate single valued functions.

%   Copyright 2022 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(nd, multiValIdx, k, l);
AUTOGRID = isempty(varargin);

% store interval index for each dimension in query point
ix = coder.nullcopy(zeros(1,nd,'like',coder.internal.indexInt(0)));

if AUTOGRID
    for i = 1:nd
        ix(i) = coder.internal.interpolate.autogridLookup(xqk(i), l(i));
    end
else
    for i=1:nd
        % locate the scattered data in the grid Vector sequences:
        if  numel(varargin{i}) > 3
            ix(i) = coder.internal.bsearch(varargin{i}, xqk(i));
        else
            ix(i) = coder.internal.indexInt(1);
        end
    end
end

assert(numel(xqk)==nd);

% ... and now set up lockstep polynomial evaluation
% First, select the relevant portion of the coefficients array.
% This has the additional pain that now there are k(i) coefficients
% for the i-th univariate interval.
% The coefficients sit in the (nd+1)-dimensional array coefs, with
% the (i+1)st dimension containing the coefficients in the i-th
% dimension, and organized to have first the highest coefficients
% for each interval, then the next-highest, etc (i.e., as if coming
% from an array of size [l(i),k(i)]).
% ix(:,j) is the index vector for the lower corner of j-th point
% The goal is to extract, for the j-th point, the requisite coefficients
% from the equivalent one-dimensional array for COEFS, computing a
% base index from ix(:,j), and adding to this the same set of offsets
% computed from the l(i) and k(i).


varargout{nd} = extractCoefForQuery(ix, coefs, l, nd, k, multiValIdx);

% ... then do a version of local polynomial evaluation
for i=nd:-1:2
    if AUTOGRID
        s = xqk(i) - cast(ix(i),'like',xqk);
    else
        s = xqk(i) - varargin{i}(ix(i));
    end

    otherk = prod(k(1:i-1));
    temp = reshape(varargout{i},[otherk,k(i)]);
    
    for j=2:k(i)
        temp(:,1) = temp(:,1).*repmat(s,[otherk,1,1])+temp(:,j);
    end
    
    varargout{i-1} = coder.nullcopy(zeros([k(1:i-1) 1],'like',varargout{i}));
    for j = 1:numel(varargout{i-1})
        varargout{i-1}(j) = temp(j,1);
    end

end
% final evaluation
if AUTOGRID
    s = xqk(1) - cast(ix(1),'like',xqk);
else
    s = xqk(1) - varargin{1}(ix(1));
end
temp = reshape(varargout{1}, [1, k(1)]);
for j=2:k(1)
    temp(:,1) = temp(:,1).*s+temp(:,j);
end
v = temp(:,1);

%--------------------------------------------------------------------------
function qpCoefs = extractCoefForQuery(ix, coefs, l, nd, k, multiValIdx)
coder.inline('always');

% Creating array for extracted coefs, it will always be of the size k for a
% single query point.
qpCoefs = coder.nullcopy(zeros(k,'like',coefs));
temp = cell(1,nd);

numMultiVal = coder.internal.indexInt(size(coefs, 1));

for i = 1:numel(qpCoefs)
    [temp{:}] = ind2sub(k,i);
    cIdx = (coder.internal.indexInt(temp{1})-1)*l(1) + ix(1);
    for j = 2:nd
        t1 = (coder.internal.indexInt(temp{j})-1)*l(j) + ix(j);
        cIdx = cIdx + (coder.internal.prodsize(coefs,'below',j+1)/numMultiVal)*(t1-1);
    end
    qpCoefs(i) = coefs(multiValIdx, cIdx);
end
