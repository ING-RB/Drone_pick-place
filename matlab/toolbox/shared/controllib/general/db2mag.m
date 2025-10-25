function y = db2mag(ydb) %#codegen
%DB2MAG  dB to magnitude conversion.
%
%   Y = DB2MAG(YDB) computes Y such that YDB = 20*log10(Y).

%   Copyright 1986-2007 The MathWorks, Inc.
%   $Revision $ 
y = 10.^(ydb/20);