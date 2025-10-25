function varargout = signedSquareDistance(mat)
%signedSquareDistance Returns signed-square distance for input matrix
%
%   SQUAREDIST = signedSquareDistance(MAT) accepts an MxN binary matrix and
%   returns an MxN matrix, SQUAREDIST, containing the signed-square 
%   distance (in pixels) between each pixel to the nearest pixel on the
%   "boundary" of an occupied region. Positive values indicate that the
%   pixel lies outside an occupied region, negative values inside, and 0
%   indicates the pixel is a boundary pixel.
%
%   [___,IDX] = signedSquareDistance(MAT) additionally returns an MxN 
%   matrix of linear indices, IDX, indicating the nearest occupied boundary
%   pixel to each pixel in MAT.

% Copyright 2022 The MathWorks, Inc.

    %#codegen

    % Ensure input is logical
    assert(islogical(mat(1)));

    % Retrieve signed-squared distance from internal bwdist utility
    [D,IDX] = bwEDT(mat);
    varargout{1} = D;
    if nargout == 2
        varargout{2} = IDX;
    end

    if (D(1) ~= inf) % If any cell is inf, they are all inf
        % Invert map
        mat = ~mat;

        % Calc inverse distance and subtract to get final result
        [D,IDX] = bwEDT(mat);
        m = D>0;
        varargout{1}(m) = varargout{1}(m) - (sqrt(D(m))-1).^2;
        if nargout == 2
            if D(1) ~= inf % If any cell is inf, they are all inf
                [i0,j0] = ind2sub(size(mat),find(m));
                [i1,j1] = ind2sub(size(mat),IDX(m));
                di = sign(i0-i1);
                dj = sign(j0-j1);
                varargout{2}(m) = sub2ind(size(mat),i1+di,j1+dj);
            else
                varargout{2}(m) = nan;
            end
        end
    end
end

function varargout = bwEDT(BW)
%bwEDT Calculate signed-square distance
    if (nargout == 2)
        numOfElements = numel(BW);
        if coder.internal.isConstTrue(numOfElements <= intmax('uint32'))
            outType = uint32(1);
        else
            outType = uint64(1);
        end
        if coder.target('MATLAB')
            [D, IDX] = imageslib.internal.bwdistComputeEDTFT(BW, outType);
        else
            D = coder.nullcopy(zeros(size(BW),'single'));
            IDX = coder.nullcopy(zeros(size(BW),'uint32'));
            [D, IDX] = imshared.coder.bwdistEDTFT(BW,D,IDX);
        end
        varargout{2} = IDX;
    else
        if coder.target('MATLAB')
            D = images.internal.builtins.bwdistComputeEDT(BW);
        else
            D = coder.nullcopy(zeros(size(BW),'single'));
            IDX = coder.nullcopy(zeros(size(BW),'uint32'));
            [D, IDX] = imshared.coder.bwdistEDTFT(BW,D,IDX);
        end
    end
    varargout{1} = D;
end