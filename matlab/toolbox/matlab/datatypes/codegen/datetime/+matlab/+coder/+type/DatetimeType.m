classdef DatetimeType < coder.type.Base
    % Custom coder type for datetime
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties
        Format
        TimeZone
    end
    
    methods (Static, Hidden)
        function m = map()
            m.Format = {'fmt',@(obj,val,access)...
                obj.setTypeProperty('Format','Properties.fmt', ...
                obj.validateFormat(val,access), access)};
            m.TimeZone = {'tz',@(obj,val,access)...
                obj.setTypeProperty('TimeZone','Properties.tz',...
                obj.validateTimeZone(val, obj.TimeZone,access), access)};
        end
        
        function resize = supportsCoderResize()
            resize.supported = true;
            resize.property = 'Properties.data';
        end
        
        function x = validateFormat(x,access)
            if isempty(access)
                if isa(x, 'coder.Constant')
                    if isa(x.Value,'string')
                        x = coder.Constant(convertStringsToChars(x.Value));
                    end
                    matlab.internal.datetime.validateFormatTokens(convertStringsToChars(x.Value),false,false);
                    
                else
                    if isequal(x.ClassName, 'string')
                        x = x.Properties.Value;
                    end
                    
                    
                    if ~matlab.internal.coder.type.util.isCharRowType(x) &&  ~matlab.internal.coder.type.util.isScalarStringType(x)
                        error(message('MATLAB:datetime:InvalidFormat'));
                    end
                end
            end
        end
        
        function x = validateTimeZone(x, oldValue, access)
            % Type editor needs this
            
            if isempty(access) && ~isequal(x, oldValue)
                if isa(x, 'coder.Constant')
                    val = convertStringsToChars(x.Value);
                elseif isa(x,'coder.Type')
                    if isequal(x.ClassName, 'string')
                        val = x.Properties.Value;
                    else
                        val = x;
                    end
                end
                                
                if isa(val,'coder.Type')
                    valid = isequal(val.ClassName,'char');
                    emptytz = valid && sum(val.SizeVector)<=1 && all(~val.VariableDims);
                else
                    valid = matlab.internal.datatypes.isScalarText(val) || isstring(val);
                    emptytz = (valid && isempty(val)) || isequal(val,"");
                end
                if ~valid
                    error(message('MATLAB:datetime:InvalidTimeZone'));
                elseif ~emptytz
                    error(message('MATLAB:datetime:UnzonedCodegen'));
                else
                    x = coder.typeof(char.empty(1,0));
                end
            end
        end
    end
end
