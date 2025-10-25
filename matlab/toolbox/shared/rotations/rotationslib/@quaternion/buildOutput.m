function q = buildOutput(q,a,b,c,d)
%   This method is for internal use only. It may be removed in the future. 
%BUILDOUTPUT build quaternion, possibly reusing existing 
%   BUILDOUTPUT(Q,A,B,C,D) builds a new quaternion from parts
%   A,B,C,D. In codegen the output is a new quaternion. In Simulation, Q
%   is reused to make the output, just changing its parts to A,B,C,D.

%   Copyright 2018 The MathWorks, Inc.    

q.a = a;
q.b = b;
q.c = c;
q.d = d;


