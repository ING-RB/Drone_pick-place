classdef (AllowedSubclasses = {?matlab.internal.coder.tabular.TableProperties, ...
        ?matlab.internal.coder.tabular.TimetableProperties}) TabularProperties %#codegen
    % Internal abstract superclass for matlab.internal.coder.tabular.TableProperties. 
    % This class is for internal use only and will change in a future release. 
    % Do not use this class.
    
    %   Copyright 2019 The MathWorks, Inc.
    
    properties ( Abstract )
        % Declare the properties common to all tables/timetables abstract
        % rather than having a mix of abstract and concrete properties in
        % order to preserve the order.
        Description
        UserData
        DimensionNames
        VariableNames
        VariableDescriptions
        VariableUnits
        VariableContinuity
        %RowNames/RowTimes
        %CustomProperties
    end
end