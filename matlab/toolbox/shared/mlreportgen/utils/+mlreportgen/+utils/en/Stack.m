classdef Stack< handle
%Stack Defines a stack of data, i.e., LIFO buffer.
%   obj = Stack() creates an instance of a stack (LIFO buffer).
%
%   Stack properties:
%      Buffer - Cell array containing stack data
%
%   Stack methods:
%      push     - Adds an item to the top of the stack
%      pop      - Remove and return the item at top of stack
%      top      - Return item at top of stack
%      contains - True if item is in the stack
%      isempty  - True for empty stack
%      add      - Adds an item to the top of the stack
%      remove   - Remove specified item anywhere in the stack
%      clear    - Remove all items in the stack

     
    %   Copyright 2019-2024 The MathWorks, Inc.

    methods
        function out=Stack
        end

        function out=add(~) %#ok<STOUT>
            %add Add object onto the stack.
            %    add(stack, obj) adds obj onto the stack.
        end

        function out=clear(~) %#ok<STOUT>
            %clear Remove all objects in the stack
            %    remove(stack) removes all objects in the stack.
        end

        function out=contains(~) %#ok<STOUT>
            %contains Return true if stack contains object
            %    contain(stack, obj) returns true if object is in the stack.
        end

        function out=isempty(~) %#ok<STOUT>
            %isempty Return true if stack is empty
            %    isempty(stack) returns true if stack is empty.
        end

        function out=pop(~) %#ok<STOUT>
            %pop Delete and return top of stack.
            %   obj = pop(stack) removes object from top of stack and
            %   returns the object.
        end

        function out=push(~) %#ok<STOUT>
            %push Push object onto the stack.
            %    push(stack, obj) pushes obj onto the stack.
        end

        function out=remove(~) %#ok<STOUT>
            %Remove specified object anywhere in the stack
            %    remove(stack, obj) removes obj anywhere in the stack.
        end

        function out=top(~) %#ok<STOUT>
            %top Return top of stack.
            %   obj = top(stack) returns a copy or handle to the item
            %   at the top of the stack, depending on whether the item
            %   is a handle object.
        end

    end
end
