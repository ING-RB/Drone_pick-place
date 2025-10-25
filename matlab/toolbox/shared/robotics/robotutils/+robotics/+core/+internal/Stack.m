classdef Stack < robotics.core.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%Stack Modified from coder.internal.stack to support stacks with different
%   width.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

    properties (SetAccess = {?robotics.core.internal.InternalAccess})
        %Data Data in the stack
        Data

        %Depth Stack depth
        Depth

        %Width Stack width
        Width

        %FixedSize Resizable stack
        FixedSize
    end

    methods

        function obj = Stack(eg, n, fixedSize)
        %Stack Constructor.
        %   It's assumed that n is a valid size, eg should be
        %   an example for the data to be stored in the stack, and
        %   fixedSize should be true for a fixed size stack, and pushing
        %   past the specified size will error. If not, the stack is
        %   dynamically grown as needed.
            if nargin > 1
                nint = n;
            else
                nint = 0;
            end

            obj.Depth = 0;

            if nargin > 2
                obj.FixedSize = logical(fixedSize);
            else
                obj.FixedSize = false;
            end

            sz = size(eg);
            obj.Width = sz(2);
            rowEg = zeros(1, obj.Width);
            
            obj.Data = repmat(rowEg,[nint, 1]);

        end


        function push(obj, x)
        %push Push an element to the stack
            coder.inline('never');
            %nd = numel(obj.Data(:,1) );
            nd = size(obj.Data,1);
            if obj.FixedSize
                coder.internal.assert(obj.Depth < nd, 'shared_robotics:robotcore:stack:StackPushLimit');
                obj.Data(obj.Depth+1, 1:obj.Width) = x;
            else
                if obj.Depth == nd
                    [nr, nc] = size(obj.Data);
                    obj.Data = [obj.Data; zeros(nr, nc)]; % will make a data copy
                    obj.Data(obj.Depth+1, 1:obj.Width) = x;
                else
                    obj.Data(obj.Depth+1, 1:obj.Width) = x;
                end
            end
            obj.Depth = obj.Depth + 1;
        end

        function y = peek(obj)
        %peek return the element from the top of the stack
            coder.inline('never');
            coder.internal.errorIf(obj.Depth <= 0, 'shared_robotics:robotcore:stack:StackPeekEmpty');
            y = obj.Data(obj.Depth, :);
        end

        function y = pop(obj)
        %pop Remove the element from the top of the stack and return the
        %element
            coder.inline('never');
            coder.internal.errorIf(obj.Depth <= 0, 'shared_robotics:robotcore:stack:StackPopEmpty');
            y = obj.Data(obj.Depth, :);
            obj.Depth = obj.Depth - 1;
        end
        
        function y = isempty(obj)
            %isempty checks whether the stack is empty or not.
            %Returns true if the stack is empty else returns false.
            coder.inline('never');
            y = false;
            if(obj.Depth <= 0)
                y = true;
            end
        end

    end


    methods (Access = public, Static = true)
        function c = matlabCodegenNontunableProperties(~)
            c = {'FixedSize'};
        end
    end
end
