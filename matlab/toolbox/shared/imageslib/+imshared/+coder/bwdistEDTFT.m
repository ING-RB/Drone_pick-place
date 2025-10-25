function [d, labels] = bwdistEDTFT(BW, d, labels) %#codegen
% bwdistEDFT - Euclidean distance transform and feature transform

idx = 1:numel(BW);
inputSize = size(BW);
numDims = numel(size(BW));

if numel(BW) == 0
    d = single(BW);
    labels = uint32(BW);
    return
end

[d, labels] = bwdistEDTFTRecursive(BW, idx, inputSize, numDims, d, labels);

% If first element is still -1 after processing, there are no feature points.
% Set output matrix elements to Inf.
if (d(1) == -1)
    for k = 1:numel(BW)
        if coder.target('MATLAB')
            % Allows code to run in MATLAB
            d(k) = Inf('single');
        else
            d(k) = coder.internal.inf('single');
        end
    end
end

% If first element is still 0 after processing, there are no feature points.  Set output matrix elements to zero.
if (labels(1) == 0)
    for k = 1:numel(BW)
        labels(k) = uint32(0);
    end
end

end

function [d, labels] = bwdistEDTFTRecursive(BW, idx, inputSize, numDims, d, labels)

numElems = 1;
cumProd = coder.nullcopy(zeros(numDims,1));
for k = 1:numDims
    numElems = numElems * inputSize(k);
    cumProd(k) = numElems;
end

if (numDims == 1 || isscalar(BW))
    [d,labels] = calcD0F0(BW, idx, numel(BW), d, labels);
else
    lengthDimN = inputSize(numDims);
    if (numDims == 2) % 2-D
        for k = 1:lengthDimN
            [d,labels] = calcFirstPassD1F1(BW, idx, inputSize(1), inputSize(1), k, d, labels);
        end
    else % N-D
        inputDimsMinusOne = numDims-1;
        elementsLow = cumProd(numDims-1);
        % Copy (N-1)-D data to temp vars.
        for k = 1:lengthDimN
            % Compute (N-1)-D distance transform and closest feature transform
            inputIndices = coder.internal.indexPlus(coder.internal.indexTimes(coder.internal.indexMinus(k,1),elementsLow),1):coder.internal.indexTimes(k,elementsLow);
            [d(inputIndices), labels(inputIndices)] = ...
                bwdistEDTFTRecursive(BW(inputIndices), idx(inputIndices),...
                inputSize, inputDimsMinusOne,...
                d(inputIndices), labels(inputIndices));
        end
        
    end
    
    % Process dimension N
    [d,labels] = processDimN(inputSize, numDims, d, labels);
end

end


function [D,F] = calcD0F0(BW, idx, vectorLength, D, F)

% Create temporary vectors to store local copy of column or row vector
D0 = coder.nullcopy(zeros(vectorLength,1,class(D)));
F0 = coder.nullcopy(zeros(vectorLength,1,class(F)));
% Initialize D0 - Feature points get set to zero, -1 otherwise
% Initialize F0 - Feature points get set to linear index, 0 otherwise
for k = 1:vectorLength
    if BW(k)
        D0(k) = single(0);
        F0(k) = uint32(idx(k));
    else
        D0(k) = single(-1);
        F0(k) = uint32(0);
    end
end

% Create temporary working vectors for voronoi generation
gDT = zeros(vectorLength,1,class(D));
h = zeros(vectorLength,1,class(D));
gFT = zeros(vectorLength,1,class(F));

% Process D0 and F0
[D0, F0] = voronoiEDTFT(gDT, gFT, h, D0, F0);

% Copy results to current N-D distance transform and closest feature transform
for k = 1:vectorLength
    D(k) = D0(k);
    F(k) = F0(k);
end

end

function [D, F] = calcFirstPassD1F1(BW, idx, vectorLength, nrows, col, D, F)

% Create temporary vectors to store local copy of column vector
D1 = coder.nullcopy(zeros(vectorLength,1,class(D)));
F1 = coder.nullcopy(zeros(vectorLength,1,class(F)));
% Initialize D1 - Feature points get set to zero, -1 otherwise
% Initialize F1 - Feature points get set to linear index, 0 otherwise
for k = 1:vectorLength
    if BW((col-1)*nrows+k) == 1
        D1(k) = single(0);
        F1(k) = uint32(idx((col-1)*nrows+k));
    else
        D1(k) = single(-1);
        F1(k) = uint32(0);
    end
end

% Create temporary working vectors fro voronoi generation
gDT = zeros(vectorLength,1,class(D));
h = zeros(vectorLength,1,class(D));
gFT = zeros(vectorLength,1,class(F));

% Process column
[D1, F1] = voronoiEDTFT(gDT, gFT, h, D1, F1);

% Copy results to current N-D distance transform and closest feature transform
for k = 1:vectorLength
    D((col-1)*nrows+k) = D1(k);
    F((col-1)*nrows+k) = F1(k);
end

end

function [D, F] = voronoiEDTFT(gDT, gFT, h, D, F)
% Note: g and h are working vectors allocated in calling function

[ns, D, F, h, gDT, gFT] = constructPartialVoronoi(D, F, h, gDT, gFT);
if (ns == 0)
    return;
end

[D, F] = queryPartialVoronoi(h, gDT, gFT, ns, D, F);


end

function  [el, D, F, h, gDT, gFT] = constructPartialVoronoi(D, F, h, gDT, gFT)

% Construct partial voronoi diagram (see Maurer et al., 2003, Figs. 3 & 5, lines 1-14)
% Note: short variable names are used to mimic the notation of the paper

el = 0;
vectorLength = numel(D);
for k = 1:vectorLength
    dk = D(k);
    fk = F(k);
    if (fk ~= uint32(0))
        if (el < 2)
            el = el + 1;
            gDT(el) = dk;
            gFT(el) = fk;
            h(el) = single(k);
        else
            while ( (el >= 2) && removeEDT(gDT(el-1), gDT(el), dk, h(el-1), h(el), single(k)) )
                el = el - 1;
            end
            el = el + 1;
            gDT(el) = dk;
            gFT(el) = fk;
            h(el) = single(k);
        end
    end
end

end

function canRemove = removeEDT(du, dv, dw, u, v, w)

a = v - u;
b = w - v;
c = w - u;

% See Eq. 2 from Maurer et al., 2003
canRemove = ((c * dv) - (b * du) - (a * dw)) > (a * b * c);

end


function [D, F] = queryPartialVoronoi(h, gDT, gFT, ns, D, F)

% Query partial Voronoi diagram (see Maurer et al., 2003, Figs. 4 & 5, lines 18-24)

el = 1;
vectorLength = numel(D);
for k = 1:vectorLength
    while ( (el < ns) && ((gDT(el) + ((h(el) - k)*(h(el) - k))) > (gDT(el+1) + ((h(el+1) - k)*(h(el+1) - k)))) )
        el = el + 1;
    end
    D(k) = gDT(el) + (h(el) - k)*(h(el) - k);
    F(k) = gFT(el);
end

end

function [D, F] = processDimN(inputSize, numDims, D, F)

% Create temporary vectors for processing along dimension N
vectorLength = inputSize(numDims);

m = 1;
n = 1;
nvectors = getNumberOfVectorsAtDimN(inputSize, numDims);

if (numDims == 2)
    linearIndexSerial = coder.nullcopy(zeros(vectorLength,1,coder.internal.indexIntClass));
    dVectorSerial = coder.nullcopy(zeros(vectorLength,1,'single'));
    fVectorSerial = coder.nullcopy(zeros(vectorLength,1,class(F)));
    gDTSerial = zeros(vectorLength,1,'single');
    hSerial = zeros(vectorLength,1,'single');
    gFTSerial = zeros(vectorLength,1,class(F));
    
    for k = 1:nvectors
        linearIndexSerial = get2DLinearIndices(inputSize(1), k, linearIndexSerial);
        [D, F] = updateEDT(dVectorSerial, fVectorSerial, linearIndexSerial, gDTSerial, gFTSerial, hSerial, D, F);
    end
else
    linearIndex = coder.nullcopy(zeros(vectorLength,1,coder.internal.indexIntClass));
    dVector = coder.nullcopy(zeros(vectorLength,1,'single'));
    fVector = coder.nullcopy(zeros(vectorLength,1,class(F)));
    gDT = zeros(vectorLength,1,'single');
    h = zeros(vectorLength,1,'single');
    gFT = zeros(vectorLength,1,class(F));
    
    for k = 1:nvectors
        linearIndex = getNDLinearIndices(nvectors, inputSize(1), m, n, linearIndex);
        if (mod(m,inputSize(1)) == 0)
            n = n + 1;
            m = 1;
        else
            m = m + 1;
        end
        [D, F] = updateEDT(dVector, fVector, linearIndex, gDT, gFT, h, D, F);
    end
end

end


function linearIndex = get2DLinearIndices(nrows, m, linearIndex)

for k = 1:numel(linearIndex)
    linearIndex(k) = ((k-1)*nrows + m);
end

end

function linearIndex = getNDLinearIndices(nvectors, nrows, m, n, linearIndex)

for k = 1:numel(linearIndex)
    linearIndex(k) = (k-1)*nvectors + (n-1)*nrows + m;
end

end

function nvectors = getNumberOfVectorsAtDimN(input_size, num_dims)

% Compute # of vectors at dimension N
nvectors = 1;
for d = 1:num_dims-1
    nvectors = nvectors * input_size(d);
end

end

function [D, F] = updateEDT(dVector, fVector, linearIndex, gDT, gFT, h, D, F)

vectorLength = numel(dVector);
% Populate temp vectors
for k = 1:vectorLength
    dVector(k) = D(linearIndex(k));
    fVector(k) = F(linearIndex(k));
end

% Process vector
[dVector, fVector] = voronoiEDTFT(gDT, gFT, h, dVector, fVector);

% Copy results to current N-D distance transform and closest feature transform
for k = 1:vectorLength
    D(linearIndex(k)) = dVector(k);
    F(linearIndex(k)) = fVector(k);
end

end
