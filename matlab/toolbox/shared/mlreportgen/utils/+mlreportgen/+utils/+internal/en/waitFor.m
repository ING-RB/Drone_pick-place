%mlreportgen.utils.internal.waitFor Waits for a function to return true
%
%   SUCCESS = mlreportgen.utils.internal.waitFor(FCN) waits for FCN to return true.
%       If FCN eventually return true, then SUCCESS will be true otherwise 
%       SUCCESS will be false.
%
%   SUCCESS = mlreportgen.utils.internal.waitFor(FCN, "TimeOut", 5) waits for FCN 
%       to return true with a time out of 5 seconds. If FCN eventually return 
%       true, then SUCCESS will be true otherwise SUCCESS will be false.
%
%   SUCCESS = mlreportgen.utils.internal.waitFor(FCN, "TimeOut", 5, "MinDelay", 0.1)  
%       waits for FCN to return true with a time out of 5 seconds and a 
%       minimum delay of 0.1 seconds. If FCN eventually return true, then 
%       SUCCESS will be true otherwise SUCCESS will be false.
%
%   Example:
%
%       filename = "to_create.txt";
%       mlreportgen.utils.internal.waitFor(@()isfile(filename));

     
    %   Copyright 2018 The MathWorks, Inc.

