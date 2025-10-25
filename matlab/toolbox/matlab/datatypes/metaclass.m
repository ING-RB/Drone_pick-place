%?    metaclass    Return matlab.metadata.Class object
%
%   mc = metaclass(H) returns the matlab.metadata.Class object for the    
%   class of H.  H can be either a scalar object or an array of 
%   objects.  The returned metaclass is always a scalar matlab.metadata.Class 
%   representing the class of H.
%
%   mc = ?ClassName will retrieve the matlab.metadata.Class object for the class 
%   with name ClassName.  The ? syntax works only with a class name and
%   not with a class instance.
%
%   Examples:
%
%   %Example 1: Retrieve the meta-class for class inputParser using a
%   class name:
%   ?inputParser
%
%   %Example 2: Retrieve the meta-class for an instance of class MException
%   obj = MException('Msg:ID','MsgTxt');
%   mc = metaclass(obj);
%
%   See also  matlab.metadata.Class, matlab.metadata.Class.fromName,
%   classdef

%   Copyright 2007-2023 The MathWorks, Inc. 
%   Built-in function.
