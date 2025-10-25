%MATLAB Code Generation Private Class
%
%   Emulates a structure using an object that is able to preserve constness
%   of some fields without requiring all fields to be constant. This is
%   used with input parsing to return parameters. For most purposes it
%   behaves like an ordinary structure, including returning 'struct' for
%   its class name and true for isstruct(obj). The main difference is that
%   new fields cannot be added or values of existing fields changed except
%   through the set method, which produces a new object each time you call
%   it. Dot assignment is not supported. If, when using the set method, you
%   attempt to assign the resulting new object back to the original object
%   variable, the success or failure of that assignment may depend on
%   whether the compiler can substitute a new variable name for you. The
%   call struct(obj) converts obj to an ordinary structure, but this may
%   cause some fields to lose constness.
%
%   coder.internal.stickyStruct objects do not work in MATLAB without being
%   compiled as part of a code generation project. Generally you should not
%   try to construct one directly. Instead, use
%   coder.internal.constantPreservingStruct or
%   coder.internal.vararginToStruct. These functions automatically
%   substitute ordinary structs when running uncompiled in MATLAB.

%   Copyright 2020-2022 The MathWorks,Inc.
%#codegen

classdef stickyStruct < coder.mixin.internal.indexing.Dot
    properties
        name
        value
        next
    end
    methods
        function obj2 = set(obj,name,value)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            obj2 = coder.internal.stickyStruct(name,value,obj);
        end
        function value = dotReference(obj,name)
            value = obj.get(name);
        end
        function obj = dotAssign(obj,name,value) %#ok<INUSD>
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            coder.internal.assert(false,'Coder:builtins:Explicit', ...
                ['Internal error. Attempted write to a read-only struct (stickyStruct). ', ...
                'Use the obj2 = set(obj,''name'',x) to create a new stickyStruct with ', ...
                'the value of obj2.name set to x, or use struct(obj) to return an ', ...
                'ordinary struct before the assignment.']);
        end
        function names = fieldnames(obj)
            names = coder.const(fieldnames(fieldnamesStruct(obj)));
        end
        function tf = isfield(obj,names)
            coder.internal.prefer_const(names);
            tf = isfield(fieldnamesStruct(obj),names);
        end
        function x = class(~)
            x = 'struct';
        end
        function x = isstruct(~)
            x = true;
        end
        function p = isa(~,cls)
            p = strcmp(cls,'struct') || strcmp(cls,'coder.internal.stickyStruct');
        end
        function s = struct(obj)
            if isempty(obj.name)
                s = struct();
            else
                s2 = struct(obj.next);
                s2.(obj.name) = obj.value;
                s = s2;
            end
        end
        function disp(obj)
            disp(struct(obj));
        end
    end
    methods (Access = private)
        function obj = stickyStruct(name,value,next)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            if nargin == 0
                obj.name = [];
                obj.value = [];
                obj.next = [];
            else
                obj.name = name;
                obj.value = value;
                obj.next = next;
            end
        end
        function value = get(obj,name)
            name = coder.const(name);
            if isequal(obj.name,[])
                value = obj.value; % not found
            elseif strcmp(name,obj.name)
                value = obj.value;
            else
                value = get(obj.next,name);
            end
        end
        function s = fieldnamesStruct(obj)
            % Make a struct with the same fieldnames as obj but without
            % data. This makes the fieldnames in the output unique.
            if isempty(obj.name)
                s = struct();
            else
                s2 = fieldnamesStruct(obj.next);
                s2.(obj.name) = zeros(0);
                s = s2;
            end
        end
        function obj2 = recursiveSet(obj,varargin)
            % Peel off an NV pair from varargin, pass to the set method,
            % and make a recursive call to peel off additional NV pairs.
            % This a low-level routine that assumes length(varargin) is
            % even.
            coder.inline('always');
            coder.internal.allowEnumInputs;
            coder.internal.prefer_const(varargin);
            if nargin <= 1
                obj2 = obj;
            else
                obj2 = recursiveSet(obj.set(varargin{1},varargin{2}),varargin{3:end});
            end
        end
    end
    methods(Static)
        function props = matlabCodegenSoftNontunableProperties(~)
            props = {'name','value'};
        end
        function obj = parse(varargin)
            coder.internal.allowEnumInputs;
            coder.internal.prefer_const(varargin);
            if nargin == 0
                % Quick return for empty case.
                obj = coder.internal.stickyStruct;
                return
            end
            narginchk(2,inf);
            % Validate the inputs. If we can't make a struct, we can't make
            % a stickyStruct.
            coder.internal.assert(mod(nargin,2)==0, 'MATLAB:StructConversion:NonPairedArgs');
            c = cell(1,nargin);
            for idx = 2:2:nargin
                c{idx-1} = varargin{idx-1}; %fieldname
                c{idx} = 0; %dummy value
            end
            struct(c{:});
            % Populate the stickyStruct.
            obj = recursiveSet(coder.internal.stickyStruct,varargin{:});
        end
    end
end