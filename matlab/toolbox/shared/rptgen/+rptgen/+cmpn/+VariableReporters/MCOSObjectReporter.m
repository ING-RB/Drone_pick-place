classdef MCOSObjectReporter < rptgen.cmpn.VariableReporters.StructuredObjectReporter
% MCOSObjectReporter generates a report for a variable whose value is an
% MCOS object.

% Copyright 1997-2018 The MathWorks, Inc.

  
  methods
    
    function moReporter = MCOSObjectReporter(moOpts, uddReport, ...
      objName, moObj)
      import rptgen.cmpn.VariableReporters.*;
      moReporter@rptgen.cmpn.VariableReporters.StructuredObjectReporter(moOpts, ...
        uddReport, objName, moObj);
    end
    
    
    function propNames = getObjectProperties(moReporter)
      % Get names of all public object properties
      metaclassObj = metaclass(moReporter.VarValue);
      props = metaclassObj.Properties;
      
      % Include only visible, public properties.
      % Note: GetAccess property can also be a meta.class object or its
      % cell array that denotes list of classes with the allowed Get access.
      % An empty cell array is same as private. We intend to include
      % properties with public Get access only.
      props = props(cellfun(@(prop) (~prop.Hidden && (ischar(prop.GetAccess) && strcmp(prop.GetAccess, 'public'))), props));
      
      if isa(moReporter.VarValue, 'meta.property')
        if ~moReporter.VarValue.HasDefault
          props = props(cellfun(@(prop) ~strcmp(prop.Name, 'DefaultValue'), props));
        end
      end
      propNames = moReporter.getObjectPropNames(props);     
    end
  
    function isFiltered = isFilteredProperty(moReporter, object, property)
      
      value = object.(property.Name);
      
      % We filter this property when...
      isFiltered = ...
          ... % It is not public  OR
          (~strcmp(property.GetAccess, 'public')) || ...
          ...
          ... % It has a default value and we are ignoring defaults  OR
          (moReporter.moOpts.IgnoreIfDefault && property.HasDefault && isequal(value, property.DefaultValue)) || ...
          ...
          ... % It is empty and we are ignoring empty values  OR
          (moReporter.moOpts.IgnoreIfEmpty && isempty(value)) || ...
          ...
          ... % Our parent told us to filter it
          (isFilteredProperty@rptgen.cmpn.VariableReporters.StructuredObjectReporter(moReporter, object, property));

    end
    
  end % of dynamic methods
  
end

