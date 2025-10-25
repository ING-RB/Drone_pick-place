function [updatedVerts] = calculateEdgeVerticesForIntersectingLabel(edgeVertViewer, labelDim, horzA, vertA, labelOrien, xdir, ydir, ax, theta)
%This calculates the LineStrip's VertexData when a label is positioned such
%that the line were to go through it

%   Copyright 2018 The MathWorks, Inc.

z1 = edgeVertViewer(3,1);
z2 = edgeVertViewer(3,2);
switch ax
    case 'y'
        hypotenuse = labelDim(1);
        xdiff = cos(theta)*hypotenuse;
        ydiff = sin(theta)*hypotenuse;

        %Create indexing for reverse and normal directions. 
        switch xdir
            case 'normal'
                idx1 = 2; idx2 = 1; 
            case 'reverse'
                idx1 = 1; idx2 = 2; xdiff = -xdiff; ydiff = -ydiff;
        end
        
        
        switch horzA
            case 'left'
                edgeVertViewer(1,idx2) = edgeVertViewer(1,idx2) + xdiff;
                edgeVertViewer(2,idx2) = edgeVertViewer(2,idx2) + ydiff;
            case 'center'
                x1 = edgeVertViewer(1,idx2);
                x4 = edgeVertViewer(1,idx1);
                x2 = mean([x1, x4]) - xdiff/2;
                x3 = mean([x1, x4]) + xdiff/2;
                
                y1 = edgeVertViewer(2,idx2);
                y4 = edgeVertViewer(2,idx1);
                y2 = mean([y1, y4]) - ydiff/2;
                y3 = mean([y1, y4]) + ydiff/2;
                zz = mean([z1, z2]);
                edgeVertViewer = [x1 x2 x3 x4; y1 y2 y3 y4; z1 zz zz z2];
                
                
                

            case 'right'
                edgeVertViewer(1, idx1) = edgeVertViewer(1, idx1) - xdiff;
                edgeVertViewer(2, idx1) = edgeVertViewer(2, idx1) - ydiff;
        end
        
    case 'x'
        switch labelOrien    
            case 'aligned'
                hypotenuse = labelDim(1);
            case 'horizontal'
                hypotenuse = labelDim(2);
        end
        
        ydiff = sin(theta)*hypotenuse;
        xdiff = cos(theta)*hypotenuse;
        
        switch ydir
            case 'normal'
                idx1 = 2; idx2 = 1;
            case 'reverse'
                idx1 = 1; idx2 = 2; xdiff = -xdiff; ydiff = -ydiff;
        end        
        
        switch vertA
            case 'top'
                edgeVertViewer(1,idx1) = edgeVertViewer(1,idx1) - ydiff;
                edgeVertViewer(2,idx1) = edgeVertViewer(2,idx1) - xdiff;
            case 'middle'
                x1 = edgeVertViewer(1,idx2);
                x4 = edgeVertViewer(1,idx1);
                x2 = mean([x1, x4]) - ydiff/2;
                x3 = mean([x1, x4]) + ydiff/2;
                
                y1 = edgeVertViewer(2, idx2);
                y4 = edgeVertViewer(2, idx1);
                y2 = mean([y1, y4]) - xdiff/2;
                y3 = mean([y1, y4]) + xdiff/2;
                
                edgeVertViewer = [x1 x2 x3 x4; y1 y2 y3 y4; z1 z1 z2 z2];

            case 'bottom'
                edgeVertViewer(1,idx2) = edgeVertViewer(1,idx2) + ydiff;
                edgeVertViewer(2,idx2) = edgeVertViewer(2,idx2) + xdiff;                
        end

end

updatedVerts = edgeVertViewer;

end
