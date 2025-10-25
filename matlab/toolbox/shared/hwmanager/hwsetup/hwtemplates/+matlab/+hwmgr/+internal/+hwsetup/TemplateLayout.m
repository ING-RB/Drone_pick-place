classdef TemplateLayout < uint64
    % TEMPLATELAYOUT - Enum specifying the supported template layout for
    % Hardware Setup templates
    % MANUAL      (1): Manual widget positions
    % GRID        (2): Grid layout
    % UNSPECIFIED (0): Unknown
    
    % Copyright 2021 The MathWorks, Inc.
    
    enumeration
      UNSPECIFIED   (0)
      MANUAL        (1)
      GRID          (2)
    end
   
    methods
        function out = toNum(obj)
            out = double(obj);
        end
    end
end