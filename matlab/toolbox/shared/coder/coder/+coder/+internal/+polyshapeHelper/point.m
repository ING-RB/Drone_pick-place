classdef point
% Base class storing vertices that make up the polyshape

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties
        X;      % Array storing all the X vertices of the polyshape
        Y;      % Array storing all the Y vertices of the polyshape
    end

    methods

        function [x, y] = getVtxArray(ptObj)
            x = ptObj.X;
            y = ptObj.Y;
        end

        function ptObj = clearAll(ptObj)
            ptObj.X = zeros(1,0);
            ptObj.Y = zeros(1,0);
        end

        function ptObj = point()
            ptObj.X = coder.internal.polyshapeHelper.point.createVarSize(zeros(1,0));
            ptObj.Y = coder.internal.polyshapeHelper.point.createVarSize(zeros(1,0));
        end

        function pt = copy(obj)
            pt = coder.internal.polyshapeHelper.point();
            pl = properties(obj);
            for k = 1:length(pl)
                if isprop(pt, pl{k})
                    pt.(pl{k}) = obj.(pl{k});
                end
            end
        end

        function ptObj = pushVtxArr(ptObj,X,Y)
            ptObj.X = horzcat(ptObj.X,X);
            ptObj.Y = horzcat(ptObj.Y,Y);
        end

        function ptObj = ptScale(ptObj, sx, sy, ox, oy, bdStPtr, bdEnPtr)
            for i = bdStPtr:bdEnPtr
                ptObj.X(i) = ox + (ptObj.X(i) - ox) * sx;
                ptObj.Y(i) = oy + (ptObj.Y(i) - oy) * sy;
                coder.internal.errorIf(isinf(ptObj.X(i)) || isinf(ptObj.Y(i)), ...
                                       'MATLAB:polyshape:scaleOverflow');
            end
        end

        function ptObj = ptRotate(ptObj, theta, ox, oy, bdStPtr, bdEnPtr)
            for i = bdStPtr:bdEnPtr
                if (~isfinite(ptObj.X(i)) || ~isfinite(ptObj.Y(i)))
                    continue;
                end

                sa = sin(theta);
                ca = cos(theta);
                ptObj.X(i) = ptObj.X(i) - ox;
                ptObj.Y(i) = ptObj.Y(i) - oy;
                X1 = ptObj.X(i) * ca - ptObj.Y(i) * sa;
                Y1 = ptObj.X(i) * sa + ptObj.Y(i) * ca;
                ptObj.X(i) = X1 + ox;
                ptObj.Y(i) = Y1 + oy;
            end
        end

        function ptObj = ptShift(ptObj, x, y, bdStPtr, bdEnPtr)
            for i = bdStPtr:bdEnPtr
                ptObj.X(i) = ptObj.X(i) + x;
                ptObj.Y(i) = ptObj.Y(i) + y;
            end
        end

        function ptObj = eraseVertices(ptObj, bdStPtr, bdEnPtr)
            ptObj.X(bdStPtr:bdEnPtr) = [];
            ptObj.Y(bdStPtr:bdEnPtr) = [];
        end

        function ptObj = reverseVtxsOfBnd(ptObj, bdStPtr, bdEnPtr)
            bndSz = bdEnPtr - bdStPtr + 1;
            numIterForRev = coder.internal.indexDivide(bndSz, 2);
            for i = 1:numIterForRev
                [ptObj.X(bdStPtr+i-1), ...
                 ptObj.X(bdEnPtr-i+1)] = coder.internal.polyshapeHelper.point.swap( ...
                    ptObj.X(bdStPtr+i-1), ptObj.X(bdEnPtr-i+1));

                [ptObj.Y(bdStPtr+i-1), ...
                 ptObj.Y(bdEnPtr-i+1)] = coder.internal.polyshapeHelper.point.swap( ...
                    ptObj.Y(bdStPtr+i-1), ptObj.Y(bdEnPtr-i+1));
            end
        end

    end

    methods(Static)

        function varOut = createVarSize(varIn)
            varOut = varIn;
            coder.varsize('varOut',[1 inf]);
        end

        function [b,a] = swap(a,b)
        end

    end

end
