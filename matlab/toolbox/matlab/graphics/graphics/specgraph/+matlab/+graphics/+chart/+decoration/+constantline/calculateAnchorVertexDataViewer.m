function anchorVert = calculateAnchorVertexDataViewer(ax, ha, va, edgeData, xdir, ydir, lo)
%Calculate the composite marker vertex data. Adds a pixel buffer depending
%on where the label is located relative to the line.

%   Copyright 2018 The MathWorks, Inc.

    pxBuffLR = 5;%PixelbufferLeftRight
    pxBuffTB = 2;%PixelBufferTopBottom
    XLim = edgeData(1,:);
    YLim = edgeData(2,:);
    
    l = 'left'; c = 'center'; r = 'right'; b = 'bottom'; m = 'middle'; t = 'top';
        
    switch ax
        case 'y'
            switch xdir
                case 'normal'
                    idx1 = 2; idx2 = 1;
                case 'reverse'
                    idx1 = 1; idx2 = 2;
            end
            switch ha
                case r
                     anchorVert = [XLim(idx1) - pxBuffLR; YLim(idx1)];
                case c
                    anchorVert = [mean(XLim); mean(YLim)];
                case l
                    anchorVert = [XLim(idx2) + pxBuffLR; YLim(idx2)];
            end
            switch va
                case t
                    anchorVert(2) = anchorVert(2) + pxBuffTB;
                case b
                    anchorVert(2) = anchorVert(2) - pxBuffTB;
            end
            
        case 'x'
            switch ydir
                case 'normal'
                    idx1 = 2; idx2 = 1;
                case 'reverse'
                    idx1 = 1; idx2 = 2;
            end
            
            switch lo
                case 'horizontal'
                    xBuff = pxBuffLR;
                    yBuff = pxBuffTB;
                case 'aligned'
                    xBuff = pxBuffTB;
                    yBuff = pxBuffLR;
            end
            
            switch va
                case t
                    anchorVert = [XLim(idx1); YLim(idx1) - yBuff];
                case m
                    anchorVert = [mean(XLim); mean(YLim)];
                case b
                    anchorVert = [XLim(idx2); YLim(idx2) + yBuff];
            end
            
            switch ha
                case r
                    anchorVert(1) = anchorVert(1) + xBuff;
                case l
                    anchorVert(1) = anchorVert(1) - xBuff;
            end             
            
    end
    
    anchorVert = single([anchorVert; edgeData(3)]);
end
