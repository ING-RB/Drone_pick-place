function ismesh = ismeshgrid(ndgrid, n)
    % helper function for erroring out with useful error message
    % if a meshgrid given instead of ndgrid

    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen
    
    coder.internal.prefer_const(n);

    ismesh = false;
    if (n == 2 || n == 3)
        Y = ndgrid{1};
        X = ndgrid{2}; 
        if (n == 2) 
            Z = [];
            zbool = true;
        else
            Z = ndgrid{3};
            zbool = ~iscolumn(Z);
        end
        
        ismesh = (~iscolumn(X) && ~iscolumn(Y) && zbool);

        if (ismesh)
            ndgridTmp = {X, Y, Z};
            [~,ismesh] = coder.internal.griddedInterpolant.createGridVectorsFromNDGrid(ndgridTmp, n);
            
        end
    end
end
