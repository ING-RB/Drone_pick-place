function Vqk = cubic_eval(VV, ND, s, ix)
% Evaluation kernel, inlining it to the function which calls it

%#codegen
coder.inline('always');
vik = zeros('like',VV);
FOUR = coder.internal.indexInt(4);
szCoefs = FOUR*ones(1,ND,'like',FOUR);
nCoefs = FOUR^ND;
for is = 1:nCoefs
    coefInd = cell(1,ND);
    [coefInd{:}] = ind2sub(szCoefs, is);
    ss = ones('like', s);
    for i = 1:ND
        ss = ss*localevaluate(s(i), coefInd{i}-1);
        coefInd{i} = coefInd{i} - 1 + cast(ix(i),'like',coefInd{i});
    end
    vik = vik + VV(sub2ind(size(VV), coefInd{:}))*ss;
end

Vqk = vik/cast(2^ND,'like',vik);

%--------------------------------------------------------------------------

function X = localevaluate(x,iter)
coder.inline('always');
coder.internal.prefer_const(iter);
if iter == 0
    X = ((2-x).*x-1).*x;
elseif iter == 1
    X = (3*x-5).*x.*x+2;
elseif iter == 2
    X = ((4-3*x).*x+1).*x;
else
    X = (x-1).*x.*x;
end