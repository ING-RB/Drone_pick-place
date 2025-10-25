function [X, isndgrid] = createGridVectorsFromNDGrid(ndgrid, n)
    % helper function to extract grid vectors from ndgrid

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.prefer_const(n);

    X = cell(1,n);
    X0 = ndgrid{1};
    numelX0 = numel(X0);
    isndgrid = (numelX0 > 0);
        
    if (n == 1)
        X{1} = X0;
    else
        isndgrid = isndgrid & (ndims(X0) == n);
        dimsX0 = size(X0,1:n);
        stride = 1;
        for i=1:n
            
            smsz = isequal(size(X0), size(ndgrid{i}));
            isndgrid = isndgrid & smsz;
            if(~isndgrid)
                break;
            end
            
            nextStride = stride * dimsX0(i);
            prodUpperDims = numelX0/nextStride;

            [~, b] = coder.internal.griddedInterpolant.extractOneGridVectorCheckNDGridness(ndgrid{i}, stride, prodUpperDims, dimsX0(i));
            isndgrid = isndgrid & b;
            if ~isndgrid
                break;
            end
            
            stride = nextStride;
            
        end
        stride = 1;
        if(isndgrid)
            for i=1:n
                smsz = isequal(size(X0), size(ndgrid{i})); 
                
                isndgrid = isndgrid & smsz;
                
                nextStride = stride * dimsX0(i);
                prodUpperDims = numelX0/nextStride;
    
                [xivec, b] = coder.internal.griddedInterpolant.extractOneGridVectorCheckNDGridness(ndgrid{i}, stride, prodUpperDims, dimsX0(i));
                isndgrid = isndgrid & b;
                
                X{i} = xivec;
                stride = nextStride;
            end
        else
            % Assigning to cell in all paths
            for i = coder.unroll(1:n)
                X{i} = zeros([1 size(ndgrid{1}, i)], 'like', ndgrid{1});
            end
        end
    end
end
