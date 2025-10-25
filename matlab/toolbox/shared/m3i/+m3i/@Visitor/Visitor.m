
%

%   Copyright 2008-2012 The MathWorks, Inc.

classdef Visitor < handle
	
    methods (Access='public')
        function this = Visitor()
            
            this.dispatcherMap = containers.Map;
            this.registerVisitor('default', 'visit');
        end
        
        function registerVisitor(this, tag, fcnPre)
			
            dispatcher = M3I.GenericVisitor();
            fcnM3I = eval(['@' fcnPre 'M3IObject']);
            dispatcher.bind( 'M3I.Object', fcnM3I );
            
            methodsOfClass = methods(this);
            for i = 1 : numel(methodsOfClass)
                methodName = methodsOfClass{i};
                trimmedMethodName = regexprep(methodName,['^' fcnPre],'');
                if ~strcmpi(methodName, trimmedMethodName)
                    visitFunction = eval(['@' methodName]);
                    dispatcher.bind( trimmedMethodName, visitFunction );
                end
            end
            
            this.dispatcherMap(tag) = dispatcher;
        end
        
        function bind(this, className, visitFcn, tag)
            if(isempty(tag))
                tag = 'default';
            end
            dispatcher = this.dispatcherMap(tag);
			dispatcher.bind(className, visitFcn);
		end
			
        function ret = visitM3IObject(~, ~)
			ret = [];
        end
        
        
        function ret = apply(this, varargin)
            if(nargin <= 1)
                error('M3I:Visitor:ToFewArgs', 'There are too few arguments to method');
            end
            
            firstArg = varargin{1};
            tag = 'default';
            obj = firstArg;
            args = varargin(2:end);
            if(ischar(firstArg)) 
                tag = firstArg;
                if(nargin <= 2)
                    error('M3I:Visitor:ToFewArgs', 'There are too few arguments to method');
                end
                obj = varargin{2};
                args = varargin(3:end);
            end
            
            dispatcher = this.dispatcherMap(tag);
			[method, actualObject] = dispatcher.fetch(obj);
            
			ret =  method(this, actualObject, args{:} );
        end
		
		function ret = apply1(this, obj, arg1)
			ret = this.apply(obj, arg1);
		end

		function ret = apply2(this, obj, arg1, arg2)
			ret = this.apply(obj, arg1, arg2);
		end

		function ret = apply3(this, obj, arg1, arg2, arg3)
            ret = this.apply(obj, arg1, arg2, arg3);
        end
        
        function ret = applySeq(this, varargin)
            if(nargin <= 1)
                error('M3I:Visitor:ToFewArgs', 'There are too few arguments to method');
            end
            
            firstArg = varargin{1};
            tag = 'default';
            seq = firstArg;
            args = varargin(2:end);
            if(ischar(firstArg))
                tag = firstArg;
                if(nargin <= 2)
                    error('M3I:Visitor:ToFewArgs', 'There are too few arguments to method');
                end
                seq = varargin{2};
                args = varargin(3:end);
            end
            
            ret = [];
            first = seq.begin;
            last = seq.end;
            iter = first;
            while iter ~= last
                item = iter.item;
                
                retone = this.apply(tag, item, args{:});
                if ~isempty(retone)
                    ret{end+1} = retone; %#ok<AGROW>
                end
                
                iter.getNext;
            end
        end
        
    end

    properties (SetAccess='protected')
		dispatcherMap;
	end

end

% LocalWords:  IObject
