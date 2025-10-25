function ignoreCatch()
%CODER.IGNORECATCH substitute a try/catch block with the body of try
%
%   If this directive is used above a try/catch block coder will codegen
%   will substitute it with the body of the try and will remove the
%   contents of the catch block.  In other words transform:
%
%       CODER.IGNORECATCH()
%       try
%           <try-body>
%       catch <catch-var>
%           <catch-body>
%
%   with:
%
%       <try-body>

%   Copyright 2019 The MathWorks, Inc.
