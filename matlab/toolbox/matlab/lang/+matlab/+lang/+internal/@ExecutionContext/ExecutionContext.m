%EXECUTIONCONTEXT  Provides conversion capabilities from an already resolved symbol
%    into a function_handle, or to construct a function_handle directly from a string
%    from the specified context. 
%
%    The conversion may or may not succeed based on whether the context has the permission
%    to execute the symbol.
%
%    In order to respect the encapsulation rule, only the current function, or the caller's 
%    function can be captured as a matlab.lang.internal.ExecutionContext.
%
%    Provides an interface to obtain the associated matlab.lang.internal.IntrospectionContext from 
%    a matlab.lang.internal.ExecutionContext, therefore perform any introspection if needed.
%
%   Copyright 2024 The MathWorks, Inc.