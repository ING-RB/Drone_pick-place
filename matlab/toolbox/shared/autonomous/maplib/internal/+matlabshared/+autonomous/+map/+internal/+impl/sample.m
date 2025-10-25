function newMat = sample(mat,newSize,type,gridOffset,resolution1,resolution2)
%sample interpolates/downsamples to match the specified size

%   Copyright 2019-2021 The MathWorks, Inc.

%#codegen

matSize = size(mat);

newMat = zeros(newSize,"like",mat);
kk1 = newSize(1):-1:1;
kk2 = 1:newSize(2);
coder.internal.assert(numel(kk1) <= size(newMat,1),'shared_autonomous:maplayer:UnboundedVariableDimension'); % g2607528
coder.internal.assert(numel(kk2) <= size(newMat,2),'shared_autonomous:maplayer:UnboundedVariableDimension'); % g2607528

% top left of grid represented by mat starts from matSize + grid offset. its cell size is
% 1/resolution1 and height and width respectively are matSize/resolution1.

% Computing lower grid lines corresponding to newMat cells in mat frame
l1 = ((matSize(1) + gridOffset(2))*resolution2 - resolution1*kk1)/resolution2;
l2 = (((kk2-1)*resolution1)-(gridOffset(1)*resolution2))/resolution2;
u1 = ((matSize(1) + gridOffset(2))*resolution2 - resolution1*(kk1-1))/resolution2;
u2 = (((kk2)*resolution1)-(gridOffset(1)*resolution2))/resolution2;
l1 = floor(l1);
l1 = l1+1;
% Computing left grid lines corresponding to newMat cells in mat frame 
l2 = floor(l2) + 1;
% Computing top grid lines corresponding to newMat cells in mat frame
u1 = ceil(u1);
% Computing right grid lines corresponding to newMat cells in mat frame
u2 = ceil(u2);

% Assert bounds
llim1 = assertBound(max(1,l1), size(newMat,1));
llim2 = assertBound(max(1,l2), size(newMat,2));
ulim1 = assertBound(min(matSize(1),u1), size(newMat,1));
ulim2 = assertBound(min(matSize(2),u2), size(newMat,2));

% Using DownSampling specified if more than one cell from mat contributes
% to cells in newMat
switch type
    case 'Max'
        for k2 = 1:newSize(2)
            for k1 = 1:newSize(1)
                newMat(k1,k2) = max(max(mat(llim1(1,k1):ulim1(1,k1),llim2(1,k2):ulim2(1,k2)),[],1),[],2);
            end
        end
    case 'AbsMax'
        for k1 = 1:newSize(1)
            for k2 = 1:newSize(2)
                matorig = mat(llim1(1,k1):ulim1(1,k1),llim2(1,k2):ulim2(1,k2));
                matabs = abs(matorig);
                [~,in] =max(matabs,[],'all','linear');
                newMat(k1,k2) = matorig(in);
            end
        end
    case 'Mean'
        for k1 = 1:newSize(1)
            for k2 = 1:newSize(2)
                newMat(k1,k2) = mean(mat(llim1(1,k1):ulim1(1,k1),llim2(1,k2):ulim2(1,k2)),'all');
            end
        end
end
end

function input = assertBound(input,uLim)
    coder.internal.assert(numel(input) <= uLim,'shared_autonomous:maplayer:UnboundedVariableDimension'); % g2607528
end
