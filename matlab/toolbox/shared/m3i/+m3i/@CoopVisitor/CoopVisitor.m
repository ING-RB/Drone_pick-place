
%

%   Copyright 2008 The MathWorks, Inc.

classdef CoopVisitor < handle
	
	methods(Access='public')
		function this = CoopVisitor	()
			methodsOfVisitorClass = methods(this);            
			for i = 1 : numel(methodsOfVisitorClass)
				methodName = methodsOfVisitorClass{i};
				classNameWithoutDots = regexprep(methodName,'^visit','');
				if ~strcmpi(methodName, classNameWithoutDots)
					visitFunction = eval(['@' methodName]);			
					tag = this.fTagManager.getTagForClassNameWithoutDots( classNameWithoutDots );
                    index = numel(this.fMethods) + 1;
                    this.fMethods{index} = visitFunction;
                    this.fMethodIndex(tag) = index;
				end
			end
        end
        
		function res = apply(this, obj)
			tagInfo = this.fTagManager.getTagInfoForObject( obj );
			try
                index = this.fMethodIndex( tagInfo{1} );
				visitFunction = this.fMethods{index};
				res = visitFunction( this, obj );
				return;
			catch				 %#ok<CTCH>
				superClassTags = tagInfo{2};
				for sc=1:length(superClassTags)
					try
                        index = this.fMethodIndex( superClassTags{sc} );
						visitFunction =  this.fMethods{index};
						res = visitFunction( this, obj );
						return;
					catch %#ok<CTCH>
					end
				end
			end
			error('sam:m3i:CoopVisitor:NoVisitationMethod', 'no method found for visitation of object: ');
			tagInfo.dispay;
		end

	end

	properties(Access='protected')
		fTagManager = m3i.TagManager.getTagManager();
		fMethods = {};
        fMethodIndex = sparse([]);
    end
	
end
