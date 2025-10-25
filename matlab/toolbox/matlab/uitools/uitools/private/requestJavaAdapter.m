function result = requestJavaAdapter(object)
%REQUESTJAVAADAPTER Support function for GUIDE

%   Copyright 1984-2010 The MathWorks, Inc.
 
%%%%%%%  CAUTION                                           %%%%%%%%
%%%%%%%  This file is duplicated in both uitools and guide %%%%%%%%%
%%%%%%%  %TODO - determine if this functionality can be    %%%%%%%%%
%%%%%%%  broken out or replaced so this file doesn't exist %%%%%%%%%
%%%%%%%  in two places                                     %%%%%%%%%
 
  len = builtin('length',object);
  if len == 1
    if (ishghandle(object) || isa(object, 'handle') || ishandle(object)) && ~isjava(object)
      %if not MCOS object cast it to handle, otherwise pass it directly to
      %java()
      if ~isobject(object) 
          if isa(object, 'double')
                % Get MCOS representation of Simulink object to avoid calling handle() for Simulink handle.
                % This will return MCOS representation of Simulink Object if applicable, otherwise, return [].
                simulinkObject = matlab.internal.getSimulinkObject(object);
                if isa(simulinkObject, 'Simulink.DABaseObject') % Valid Simulink Object
                    object = simulinkObject;
                end
          end
          
          if isa(object, 'Simulink.DABaseObject') 
              result = java(object);
          else
              result = java(handle(object));
          end
      else
          if ~isa(object, 'JavaVisible')
              error(message('MATLAB:requestJavaAdapter:invalidobject'));
          end
          
          result=java(object);
      end
    else
      error(message('MATLAB:requestJavaAdapter:InvalidInput'));
    end
  else
    if ~isempty(object) && (all(ishghandle(object)) || all(isa(object, 'handle') || all(ishandle(object))) && ~isjava(object))
        result = cell(len, 1);
        if all(isobject(object))
            for i = 1:len
                result{i}=java(object(i));
            end
        else
            for i = 1:len
                result{i} = java(handle(object(i)));
            end
        end
    else
        error(message('MATLAB:requestJavaAdapter:InvalidArgument'));
    end
  end
