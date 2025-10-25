classdef CategoricalType < coder.type.Base
    % Custom coder type for categorical
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
       Categories;
       Ordinal;
       Protected;
    end
 
    methods (Static, Hidden)
        function m = map()
            m.Categories = {'categoryNames',@(obj, val, access) ...
                obj.setTypeProperty('Categories', 'Properties.categoryNames', ...
                obj.validateCategories(val,access), access)};
            m.Ordinal = {'isOrdinal',@(obj, val, access) ...
                obj.setTypeProperty('Ordinal', 'Properties.isOrdinal', ...
                obj.validateLogicalScalar(val, access, 'Ordinal'), access)};
            m.Protected = {'isProtected',@(obj, val, access) ...
                obj.setTypeProperty('Protected', 'Properties.isProtected', ...
                obj.validateLogicalScalar(val, access, 'Protected'), access)};
        end
        
        function c = homogeneous()
            c.Categories = true;
        end
        
        function resize = supportsCoderResize()
            resize.supported = true;
            resize.property = 'Properties.codes';
        end
        
        function x = validateCategories(x,access)
            if isa(x, 'coder.Constant')
                val = x.Value;
            else
                val = x;
            end
            if ~matlab.internal.coder.type.util.isFullAssignment(access)
                if numel(access) == 2 && isequal({access.type}, {'.', '{}'}) && ...
                        strcmp(access(1).subs, 'Cells')
                    % assigning individual cell
                    valid = matlab.internal.coder.type.util.isCharRowType(val, false); % don't allow empty char
                else
                    % for all other assignments type.Categories.xxx = yyy,
                    % do not validate
                    valid = true;
                end
            else
                if isa(val, 'coder.Type')
                    % allow variable size
                    isColumnOrEmptyType = val.SizeVector(2) == 1 || isequal(val.SizeVector,[0 0]);
                else
                    isColumnOrEmptyType = iscolumn(val) || isequal(size(val),[0 0]);
                end
                valid = isColumnOrEmptyType && matlab.internal.coder.type.util.isCellstrType(val, false); % don't allow empty char
            end
            if ~valid
                error(message('MATLAB:categorical:InvalidCategoriesType'));
            end
        end
        
        function x = validateLogicalScalar(x,access,propname)
            % do not validate when access is nonempty: type.(propname).xxx = yyy
            if matlab.internal.coder.type.util.isFullAssignment(access)
                if isa(x, 'coder.Constant')
                    val = x.Value;
                else
                    val = x;
                end
                
                if isa(val, 'coder.Type')
                    islogicalscalar = strcmp(val.ClassName, 'logical') && ...
                        isequal(val.SizeVector, [1 1]) && ~any(val.VariableDims);
                else
                    islogicalscalar = islogical(val) && isscalar(val);
                end
                if ~islogicalscalar
                    error(message('MATLAB:categorical:InvalidLogicalScalarType',propname));
                end
            end
        end
    end
end