function out = imresizegpuArray(in, weights, indices, dim)
% resize image along each dimension for gpuArray/imresize

% Copyright 2020 The MathWorks, Inc.

checkInput(in, weights, indices, dim);

type = classUnderlying(in);
weightsPerPixel = size(weights,1);

% create a variable for casting in arrayfun
tempVar = cast(1,type);

% check whether is complex image
if isreal(in)
    iniValue = 0;
else
    iniValue = complex(0,0);
end

if dim == 1
    %resize along row
    rowIndex = gpuArray.colon(1,1,size(weights,2))';
    colIndex = gpuArray.colon(1,1,size(in,2));
    zLoc = reshape(gpuArray.colon(1,1,size(in, 3)),1,1,[]);
    out = arrayfun(@calculateOutRow, rowIndex, colIndex, zLoc, weightsPerPixel, iniValue);

else
    %resize along col
    rowIndex = gpuArray.colon(1,1,size(in,1))';
    colIndex = gpuArray.colon(1,1,size(weights,2));
    
    zLoc = reshape(gpuArray.colon(1,1,size(in,3)),1,1,[]);
    out = arrayfun(@calculateOutCol, rowIndex, colIndex, zLoc, weightsPerPixel, iniValue);

end

    function Out = calculateOutRow(row, col, zLoc, weightsPerPixel, iniValue)

        out = iniValue;
        for ii = 1:weightsPerPixel
            var = in(indices(ii,row), col, zLoc);
            elem = cast(var, 'double');
            out = out + weights(ii,row)*elem;
        end
        Out = cast(out, 'like', tempVar);
        
    end

    function Out = calculateOutCol(row, col, zLoc, weightsPerPixel, iniValue)
    
        out = iniValue;
        for ii = 1:weightsPerPixel
            var = in(row, indices(ii,col),zLoc);
            elem = cast(var, 'double');
            out = out + weights(ii,col)*elem;
        end
        Out = cast(out, 'like', tempVar);
        
    end

end



function checkInput(in, weights, indices, dim)
% check input image

if ~isnumeric(in)||issparse(in)
    error(message("MATLAB::images::resizeDim::invalidImage"));
end

if (~isequal(classUnderlying(weights),'double'))||issparse(weights)||~isequal(ndims(weights),2)
    error(message("MATLAB::images::resizeDim::badWeights"));
end

if (~isa(indices,'double'))||issparse(indices)
    error(message("MATLAB::images::resizeDim::badIndices"));
end

if ~isequal(size(weights),size(indices))
    error(message("MATLAB::images::resizeDim::sizeMismatch"));
end

if (~isequal(classUnderlying(dim),'double'))||issparse(dim)
    error(message("MATLAB::images::resizeDim::invalidDim"));
end

end
