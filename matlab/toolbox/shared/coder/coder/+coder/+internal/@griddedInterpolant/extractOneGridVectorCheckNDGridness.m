function [xivec,b] = extractOneGridVectorCheckNDGridness(Xi, stride, prodUpperDims, xivecNumel)
    % checks if the input is a valid ndgrid

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    xii = 1;
    xivec = coder.nullcopy(zeros(1,xivecNumel,'like',Xi));
    for i = 1:xivecNumel
        xivec(i) = Xi(xii);
        xii = xii + stride;
    end
    
    b = true;
    xii = 1;
    for i=1:prodUpperDims
        for j = 1:xivecNumel
            for k=1:stride
                if (~isequal(xivec(j),Xi(xii))) 
                    % should isequal be used or tolerance ?
                    b = false;
                    break;
                end
                xii = xii + 1;
            end
        end
    end

end
