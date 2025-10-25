function newMat = sample(mat,newSize,type,gridOffset,resolution1,resolution2)
%SAMPLE samples(upsample/downsample) the matrix to the specified new size
%and returns the sampled matrix newMat.
%   If multiple cells from mat overlap the sample cell in newMat then down
%   sampling is used. One of {'Max','AbsMax','Mean'} can be chosen as down
%   sample strategy using type input. gridOffset specifies the cell
%   distance between the top left corner of mat and newMat. gridOffset can
%   be used to set the top left corner position w.r.t bottom left ([1,1])
%   of mat. The newMat top left is computed as
%   [size(mat,1)+gridOffset(1),-gridOffset(2]. resolution1, resolution2
%   specifies the number of cells per meter in mat and newMat respectively.

%   Copyright 2019-2021 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(resolution1); % g2607528
coder.internal.prefer_const(resolution2); % g2607528
matSize = size(mat);
if (resolution1==resolution2)&&all(newSize==matSize)&&all(gridOffset==0)
    % no sampling required when resolutions match. grid offset need not be
    % considered because when the resolutions are same after move or write
    % from othermap the offset between both the grids will always be zero.
    newMat = mat;
elseif (rem(resolution1,resolution2)==0)&&all(gridOffset==0)&&coder.target('MATLAB')
    % Faster downsampling when resolution2 is integer multiple of
    % resolution1. Grid offset will always be zero in this case because the
    % grid lines in sampled matrix will always be grid lines of original
    % matrix (1/resolution2 is integral multiple of 1/resolution1).
    resRatio = resolution1/resolution2;
    switch type
        case 'Max'
            newMat = reshape(max(reshape(reshape(max(reshape(mat,resRatio,[])),...
                    newSize(1),[])',resRatio,[])),newSize(2),[])';
        case 'Mean'
            newMat = cast(reshape(sum(reshape(reshape(sum(reshape(double(mat),resRatio,[])),...
                    newSize(1),[])',resRatio,[])),newSize(2),[])/(resRatio*resRatio),'like',mat)';
        case 'AbsMax'
            m1 = reshape(mat,resRatio,[]);
            [m2,in1] = max(abs(m1),[],1,'linear');
            [m3,in2] = max(reshape(reshape(m2,newSize(1),[])',resRatio,[]),[],1,'linear');
            signMat = reshape(reshape(sign(m1(in1)),newSize(1),[])',resRatio,[]);
            newMat = reshape(m3.*signMat(in2),newSize(2),[])';
    end
elseif (resolution2~=resolution1)&&(rem(resolution2,resolution1)==0)&&coder.target('MATLAB')
    % Faster upsampling in case resolution2 is integral multiple of
    % resolution1
    resRatio = resolution2/resolution1;
    m = matSize(1)*resRatio;
    if all(gridOffset==0)
        newMat = reshape(repmat(reshape(repmat(mat(:)',resRatio,1),m,[]),resRatio,1),m,[]);
    else
        gOffset = gridOffset*resRatio;
        nMat = reshape(repmat(reshape(repmat(mat(:)',resRatio,1),m,[]),resRatio,1),m,[]);
        newMat = nMat(round(m+gOffset(2)-newSize(1)+1):round(m+gOffset(2)),round(-gOffset(1)+1):round(-gOffset(1)+newSize(2)));
    end
else
    % Do sampling with for loops in all the other cases.
    if coder.target('MATLAB')
        newMat = matlabshared.autonomous.map.internal.mex.sample(double(mat),newSize,type,gridOffset,resolution1,resolution2);
    else
        newMat = matlabshared.autonomous.map.internal.impl.sample(mat,newSize,type,gridOffset,resolution1,resolution2);
    end
end
end

