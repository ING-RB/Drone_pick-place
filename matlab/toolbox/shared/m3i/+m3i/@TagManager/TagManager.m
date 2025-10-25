
%

%   Copyright 2008 The MathWorks, Inc.

classdef TagManager < hgsetget
	
	methods(Access='public', Static=true)
		function res = getTagManager()
			persistent sTagManager;
			if isempty(sTagManager)
				sTagManager = m3i.TagManager();
			end
			res = sTagManager;
		end
	end
	
	methods(Access='public')   
        
		function res = getTagInfoForClass(this, aMetaClass)
			classNameWithoutDots = strrep( aMetaClass.Name, '.', '');
			tag = 0;
			tagList = [];
			try
				res = this.fClassToTagInfo.(classNameWithoutDots);
				tag = res{1};
				tagList = res{2};
            catch
				superClasses = this.getSuperClassesInOrder(aMetaClass);
				nSuperClasses = length(superClasses);
				superClassTagList = cell(1,nSuperClasses);
				superClassNameList = cell(1,nSuperClasses);
				for i=nSuperClasses:-1:1
					superClass = superClasses{i};
					tagInfoForSuperClass  = this.getTagInfoForClass( superClass );
					superClassTagList{i}  = tagInfoForSuperClass{1};
					superClassNameList{i} = superClass.Name;
				end

				if tag == 0 
					tag  = this.fTagCounter;
					this.fTagCounter  = this.fTagCounter + 1;
				end
				
				res {1} = tag;
				res {2} = superClassTagList;
				res {3} = aMetaClass.Name;
 				res {4} = superClassNameList;
				this.fClassToTagInfo.(classNameWithoutDots) = res;
				this.fTagToClass{tag} = aMetaClass;
			end 
		end
		
		function res = getTagInfoForObject(this, obj)
			className = class( obj );	
			classNameWithoutDots = strrep( className, '.', '');	
			try 				
				res = this.fClassToTagInfo.(classNameWithoutDots);
				arr = res{2};
			catch %#ok<CTCH>
				metaClass = meta.class.fromName(className);
				res = this.getTagInfoForClass( metaClass );
			end
		end
		
		function res = getTagForClassNameWithoutDots(this, aClassNameWithoutDots)
			try
				res = this.fClassToTagInfo.(aClassNameWithoutDots){1};
			catch %#ok<CTCH>
				tag  = this.fTagCounter;
				this.fTagCounter  = this.fTagCounter + 1;			
				this.fClassToTagInfo.(aClassNameWithoutDots){1} = tag;
				res = tag;
			end						
		end
		
	end
	
	methods(Access='private')
		function res = getSuperClasses(this, index, worklist)
			if index <= length(worklist)
				metaClass = worklist{index};
				superClasses = metaClass.SuperClasses;
				worklist = [ worklist superClasses ];
				res = this.getSuperClasses(index+1, worklist);
			else
				res = worklist;
			end
			
			if index == 1
				res = res(2:length(res));
			end
		end
		
		function res = getSuperClassesInOrder(this, aMetaClass)
			superClasses = this.getSuperClasses(1, {aMetaClass} );
			size = 0;
			len = numel(superClasses);
			res = {};
			for sc=len:-1:1
				superClass = superClasses{sc};
				found = false;
				for i=1:size
					if res{i} == superClass
						found = true;
						break;
					end
				end
				if found == false
					size = size + 1;
					res{size} = superClass;
				end
			end
			res = fliplr(res);
        end        		
	end

	properties(Access='private')
		fTagCounter = 1;
		fClassToTagInfo = {};
		fTagToClass = {};
	end
	
end
