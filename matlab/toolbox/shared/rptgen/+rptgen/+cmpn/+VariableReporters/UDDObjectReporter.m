classdef UDDObjectReporter < rptgen.cmpn.VariableReporters.StructuredObjectReporter
% UDDObjectReporter generates a report for a variable whose value is a
% UDD object.

% Copyright 1997-2011 The MathWorks, Inc.

  
  methods
    
    function moReporter = UDDObjectReporter(moOpts, uddReport, ...
      objName, uddObj)
      import rptgen.cmpn.VariableReporters.*;
      moReporter@rptgen.cmpn.VariableReporters.StructuredObjectReporter(moOpts, ...
        uddReport, objName, uddObj);
    end
    

    
    function propNames = getObjectProperties(moReporter)      
      propNames = {};     
      if ~isa(moReporter.VarValue, 'handle.listener')
        % Get names of all visible object properties
        metaclassObj = classhandle(moReporter.VarValue);
        if ~isempty(metaclassObj.Properties)
          propSchemas = find(metaclassObj.Properties,'Visible','on');
          nProps = length(propSchemas);
          props = cell(nProps, 1);
          for i = 1:nProps
            props{i} = propSchemas(i);
          end
          propNames = getObjectPropNames(moReporter, props);
        end
      end
    end

    function fields = getStructFields(struct)
      fields = fieldnames(struct);
    end

  
    function isFiltered = isFilteredProperty(moReporter, object, property)
      
      try
          
        access = property.Access;
        value = object.(property.Name);
        
        % Filter this property if:
        isFiltered = ...
            (~strcmp(access.PublicGet, 'on')) ||                    ...                                                 % It is not publicly visible  OR
                                                                    ...
            (moReporter.moOpts.IgnoreIfDefault && isequal(value, property.FactoryValue)) || ...                         % This is a default and defaults are ignored  OR
            ...
            (moReporter.moOpts.IgnoreIfEmpty && isempty(value)) ||  ...                                                 % This is empty and empty values are ignored  OR
                                                                    ...
            (isFilteredProperty@rptgen.cmpn.VariableReporters.StructuredObjectReporter(moReporter, object, property));  % Our parent tells us to

      catch %#ok<CTCH>
        isFiltered = true;
      end
      
    end
  

    
  end % of dynamic methods
  
end

