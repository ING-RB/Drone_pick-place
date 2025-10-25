classdef (HandleCompatible) MissingSubclassHandler
% This mixin class hosts methods that are used to handle a load time
% ClassNotFound error.

%   Copyright 2022 The MathWorks, Inc.

   methods(Access = protected, Abstract= true, Static = true)
         % This method will be called at save time to store additional info
         % in the matfile
         % Input argument - subclass - is the meta class object of the
         %                             instance being saved
         % Output argument - savedInfo - is the information stored in the
         %                               matfile,needed at load time, to
         %                               handle a ClassNotFound error
         savedInfo = addSubclassInfo(subclass)

         % This method will be called at load time when a ClassNotFound error occurs
         % Input argument - subclassName - is the MATLAB string
         %                                 representation of the class name
         %                                 whose class definition is not
         %                                 known to MATLAB, at load time.
         %                  savedInfo - is the information stored in the
         %                              matfile, obtained as output from the
         %                              "addSubclassInfo". This is needed
         %                              to handle a ClassNotFound error
         defineMissingSubclass(subclassName,savedInfo)

    end
end

