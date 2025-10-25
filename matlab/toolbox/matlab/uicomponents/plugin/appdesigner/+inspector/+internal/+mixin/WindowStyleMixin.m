classdef WindowStyleMixin < handle	
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2020 The MathWorks, Inc.
	
	properties(SetObservable = true)		
		WindowStyle inspector.internal.datatype.WindowStyle
	end
	
	methods
		function set.WindowStyle(obj, inspectorValue)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).WindowStyle, char(inspectorValue))
                    obj.OriginalObjects(idx).WindowStyle = char(inspectorValue); %#ok<*MCNPR>
                end
            end
		end		
		
		function value = get.WindowStyle(obj)
			value = inspector.internal.datatype.WindowStyle.(obj.OriginalObjects(end).WindowStyle);
		end
	end
end
