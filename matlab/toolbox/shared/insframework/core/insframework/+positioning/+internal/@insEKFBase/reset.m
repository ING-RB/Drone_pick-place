function reset(filt) 
%RESET reset State and StateCovariance properties
%   Reset the filter's State and StateCovariance properties to
%   their initial values after filter construction.

%   Copyright 2022 The MathWorks, Inc.    

%#codegen 

    initializeState(filt);
    initializeStateCovariance(filt);
end
