classdef WorkingSet
% Generate working sets from the input image
%
% hdl.WorkingSet(image, workingSetSize, varargin) creates a
% WorkingSet object that enables you to generate and return working sets
% from the input image based on the specified line buffer properties.
% This object has the simulation behavior and must be used inside the
% MATLAB test bench.
%
% WorkingSet Methods:
%   getWorkingSet(x,y) - Returns the working set corresponding to the pixel
%                        at position (x,y) in the input image.
%
% Example:
%   image = rand(20, 20);
%   ws = hdl.WorkingSet(image, [3 3], "Origin", [2 2], "FillMethod", "ConstantFill","FillValue", -1);
%   for x = 1:20
%       for y = 1:20
%           workingSet = ws.getWorkingSet(x, y);
%           out = sum(workingSet(:));
%       end
%   end

% Example:
%   image = rand(20, 20);
%   ws = hdl.WorkingSet(image, [3 3], "FillMethod", "Nearest");
%   while ws.hasNextWorkingSet()
%       [obj, workingSet]= ws.nextWorkingSet();
%       out = sum(workingSet(:));
%   end
%  

%   Copyright 2022-2023 The MathWorks, Inc.
%
    properties (Access = private)
        imagePadded
        leftOffset
        rightOffset
        topOffset
        bottomOffset
        bound
        boundX
        boundY
        curX
        curY
    end

    properties (Access = public)
        image
        workingSetSize
        Origin
    end

    methods(Access = private)
        % Get current position 
        function pos = getElementPos(obj)
            pos = getPos(obj, obj.curX, obj.curY);
        end

        % Get position at some (i,j) 
        function pos = getPos(obj, i, j)
            [~, cols] = size(obj.image);
            pos = ( (i-1)*cols) + j;
        end

        % Initialization of 'ConstantFill' boundary fill method
        % ConstantFill : Each value is filled with a constant value. The constant defaults to 0, but can be changed by calling set_fill_value (<val>).
        % constant padding is used to implement 'ConstantFill' boundary fill method
        function obj = constantFill(obj, cfill)
            [rows, cols] = size(obj.image);
            obj.bound = (rows*cols);
            obj.boundX = rows;
            obj.boundY = cols;
            obj.curX = 1;
            obj.curY = 1;
            obj.imagePadded = padarray(obj.image, [obj.bottomOffset obj.rightOffset], cfill, "post");
            obj.imagePadded = padarray(obj.imagePadded, [obj.topOffset, obj.leftOffset], cfill, "pre");
        end

        % Initialization of 'Nearest' boundary fill method
        % Nearest : The value from the nearest location at the edge of the parameter will be used as fill.
        % 'replicate' padding is used to implement 'Nearest' boundary fill method
        function obj = nearest(obj)
            [rows, cols] = size(obj.image);
            obj.bound = (rows*cols);
            obj.boundX = rows;
            obj.boundY = cols;
            obj.curX = 1;
            obj.curY = 1;
            obj.imagePadded = padarray(obj.image, [obj.bottomOffset obj.rightOffset], "replicate", "post");
            obj.imagePadded = padarray(obj.imagePadded, [obj.topOffset obj.leftOffset], "replicate", "pre");
        end

        % Initialization of 'Reflected' boundary fill method
        % Reflected :  Each value outside the parameter's edge will be filled with a value that is within the parameter and an equivalent distance from the parameter's edge.
        % 'symmetric' padding is used to implement 'Reflected' boundary fill method
        function obj = reflected(obj)
            [rows, cols] = size(obj.image);
            obj.bound = (rows*cols);
            obj.boundX = rows;
            obj.boundY = cols;
            obj.curX = 1;
            obj.curY = 1;
            obj.imagePadded = padarray(obj.image, [obj.bottomOffset+1 obj.rightOffset+1], "symmetric", "post");
            obj.imagePadded(:, cols + obj.rightOffset + 1) = [];
            obj.imagePadded = padarray(obj.imagePadded, [obj.topOffset+1 obj.leftOffset+1], "symmetric", "pre");
            obj.imagePadded(rows + obj.bottomOffset + 1, :) = [];
            obj.imagePadded(obj.topOffset+1, :) = [];
            obj.imagePadded(:, obj.leftOffset + 1) = [];
        end

        % Initialization of 'Wrap' boundary fill method
        % Wrap : Boundary values are filled with values wrapped around from the preceding, or succeeding rows.
        % Wrap is implemented by concatenation of first 2 columns (shifted by 1 row) of input image matrix to the end of original image matrix
        function obj = wrap(obj)
            [rows, cols] = size(obj.image);
            obj.curX = 1;
            obj.curY = 1;
            obj.bound = getPos(obj, rows - obj.workingSetSize(1) + 1, cols - obj.workingSetSize(2) + 1);
            obj.boundX = rows - obj.workingSetSize(1) +1;
            obj.boundY = cols - obj.workingSetSize(2) +1;
            tmpObj = obj.image(2 : end, 1 : obj.rightOffset);
            tmpObj = [tmpObj; obj.image(1, 1 : obj.rightOffset)];
            obj.imagePadded = [obj.image tmpObj];
        end
    end

    methods (Access = public)
        function obj = WorkingSet(image, workingSetSize, varargin)

            arguments
                image {mustBeA(image,{'embedded.fi', 'numeric'})}
                workingSetSize {mustBeVector, mustBePositive}
            end

            arguments(Repeating)
                varargin
            end

            % Image must be 2D
            coder.internal.assert(ismatrix(image) && numel(size(image)) == 2,...
                                   'hdlmllib:hdlmllib:ImageMustBe2D');

            % Dimensions of working set must be same as dimensions of image 
            coder.internal.assert(isequal(nnz(workingSetSize), nnz(size(image))),...
                                  'hdlmllib:hdlmllib:KernelSizeIncorrect');

            % Kernel should fit inside the image
            isKernelInsideImage = all(workingSetSize <= size(image))  && all(workingSetSize > 0);
            coder.internal.assert(isKernelInsideImage ,...
                                  'hdlmllib:hdlmllib:KernelShouldFitInsideImage');

            FillMethodSupport = {'ConstantFill', 'Reflected', 'Nearest', 'Wrap'};
            options = struct('Origin', [1 1], 'FillMethod', 'ConstantFill', 'FillValue', 0);
            MethodsDefined = struct('Origin', 0, 'FillMethod', 0, 'FillValue', 0);

            for ind = 1:2:numel(varargin)
                name = varargin{ind};
                if any(strcmp(fieldnames(options), name))
                    if isequal(name, "Origin")
                        % error More than one value passed for the parameter 'Origin'
                        coder.internal.assert(~MethodsDefined.Origin,...
                                              "hdlmllib:hdlmllib:MoreThanOneParameter",name);

                        if ind == numel(varargin)
                            coder.internal.error('hdlmllib:hdlmllib:InvalidOrigin');
                        end

                        curOrigin = varargin{ind + 1};

                        % Origin fits inside the kernel
                        coder.internal.assert(nnz(curOrigin) == 2 && all(curOrigin <= workingSetSize) && all(curOrigin > 0) && all(mod(curOrigin, 1) == 0),...
                                              'hdlmllib:hdlmllib:InvalidOrigin');

                        options.Origin = curOrigin;
                        MethodsDefined.Origin = 1;
                    elseif isequal(name, "FillMethod")
                        % error More than one value passed for the parameter 'FillMethod'
                        coder.internal.assert(~MethodsDefined.FillMethod,...
                                              "hdlmllib:hdlmllib:MoreThanOneParameter",name);

                        curMethod = varargin{ind + 1};
                        mustBeMember(curMethod, FillMethodSupport);
                        options.FillMethod = curMethod;
                        MethodsDefined.FillMethod = 1;
                    else
                        % error More than one value passed for the parameter 'FillValue'
                        coder.internal.assert(~MethodsDefined.FillValue,...
                                              "hdlmllib:hdlmllib:MoreThanOneParameter",name);

                        if ind == numel(varargin)
                            coder.internal.error('hdlmllib:hdlmllib:InvalidBoundaryConstant');
                        end

                        curVal = varargin{ind + 1};
                        validBoundaryConst = isnumeric(curVal) && isscalar(curVal);

                        coder.internal.assert(validBoundaryConst,...
                                              'hdlmllib:hdlmllib:InvalidBoundaryConstant');

                        options.FillValue = curVal;
                        MethodsDefined.FillValue = 1;
                    end
                else
                    % error invalid parameter
                    coder.internal.error("hdlmllib:hdlmllib:InvalidParameter",name);
                end
            end

            if ~MethodsDefined.Origin
                if isequal(options.FillMethod, 'Wrap')
                    options.Origin = [1 1];
                else
                    options.Origin = floorDiv(workingSetSize + 1, 2);
                end
            end



            FillValue = options.FillValue;
            Origin = options.Origin;
            FillMethod = options.FillMethod;

            % For wrap boundary fill method : origin must be [1, 1]
            if isequal(FillMethod, 'Wrap')
                coder.internal.assert(isequal(Origin, [1 1]),...
                                      'hdlmllib:hdlmllib:OriginProvidedInWrapMethod');
            end

            if ~isequal(FillMethod, 'ConstantFill')
                if MethodsDefined.FillValue
                    warning(message("hdlmllib:hdlmllib:ArgumentPassedToFillHasNoEffect"));
                end
            end

            obj.boundX = 0;
            obj.boundY = 0;
            obj.curX = 0;
            obj.curY = 0;
            obj.bound = 0;
            obj.image = image;
            obj.workingSetSize = workingSetSize;
            obj.Origin = Origin;
            obj.leftOffset = obj.Origin(2) - 1;
            obj.rightOffset = workingSetSize(2) - obj.Origin(2);
            obj.topOffset = obj.Origin(1) - 1;
            obj.bottomOffset = workingSetSize(1) - obj.Origin(1);

            % Initialization of object
            if FillMethod =="ConstantFill"
                    obj = obj.constantFill(FillValue);
            elseif FillMethod == "Nearest"
                    obj = obj.nearest();
            elseif FillMethod == "Reflected"
                    obj = obj.reflected();
            elseif FillMethod == "Wrap"
                    obj = obj.wrap();
            end
        end

        function [obj, workingSet] = nextWorkingSet(obj)
            posAtEnd = obj.getElementPos() == obj.bound;
            coder.internal.assert(~posAtEnd,'hdlmllib:hdlmllib:NoMoreWorkingSets');

            [~, m] = size(obj.image);

            if obj.curX == obj.boundX
                obj.curY = obj.curY + 1;
            else
                if obj.curY == m
                    obj.curY = 1;
                    obj.curX = obj.curX + 1;
                else
                    obj.curY = obj.curY + 1;
                end
            end

            workingSet = obj.getWorkingSet(obj.curX, obj.curY);
        end

        function workingSet = getWorkingSet(obj, i, j)
            % check for validity of pixel (i,j)
            isPosOutOfBounds = (i < 0) || (j < 0) || (i > obj.boundX ) || (i == obj.boundX && j > obj.boundY);
            coder.internal.assert( ~isPosOutOfBounds,...
                                  'hdlmllib:hdlmllib:InvalidPixel');

            iPadded = i + obj.topOffset;
            jPadded = j + obj.leftOffset;
            workingSet = obj.imagePadded(iPadded - obj.topOffset: iPadded + obj.bottomOffset, jPadded - obj.leftOffset : jPadded + obj.rightOffset);
        end

        % Get working set at current position
        function workingSet = currentWorkingSet(obj)
            if obj.hasNextWorkingSet() == false
                workingSet = -1;
                return;
            end
            workingSet = obj.getWorkingSet(obj.curX, obj.curY);
        end

        function res = hasNextWorkingSet(obj)
            if obj.curX == obj.boundX
                if obj.curY == obj.boundY
                    res = false;
                    return;
                else
                    res = true;
                    return;
                end
            end
            res = true;
        end
    end
end
% LocalWords:  ws Kernelshould
