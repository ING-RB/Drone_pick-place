classdef DataModel < internal.matlab.variableeditor.CloneableVariable & internal.matlab.variableeditor.VariableObserver
    % An abstract class defining the methods for a Data Model
    % 

    % Copyright 2013-2024 The MathWorks, Inc.

    events
       DataChange; % Fired when data has changed
    end
   
    % Public Abstract Methods
    methods(Access='public',Abstract=true)
        %getType
        type = getType(this);
        
        %getClassType
        type = getClassType(this);
    end

         
  
end %classdef
