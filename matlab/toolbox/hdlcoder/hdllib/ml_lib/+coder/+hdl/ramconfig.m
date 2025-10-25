%CODER.HDL.RAMCONFIG Specify RAM Mapping configuration
%
%   With the coder.hdl.ramconfig pragma, you can specify what variables
%   should be mapped to RAM and what type of RAM is generated.
%
%   If one or more variables are specified, coder.hdl.ramconfig sets the
%   RAM Mapping configuration for those variables (ignoring the RAM Mapping
%   threshold). If no variables are specified, coder.hdl.ramconfig sets
%   the default RAM Mapping configuration for all variables that meet
%   the RAM Mapping threshold.
%
%   RAM options:
%
%      RAMType:
%         'Single port', 'Simple Dual Port', 'Dual Port', 'Simple Tri
%          Port'.  'True dual port' is not supported.  The type of RAM the
%          variable(s) are mapped to. Default value: 'Simple Dual Port'.
%      WriteOutputValue:
%         'New data' or 'Old data'. Whether the output value from writes
%         is the data previously in the RAM or the new data being written.
%         This only affects the generated HDL; RAM Mapping does not use
%         write ports to simultaneously perform a read and write. Default
%         value: 'New data'.
%      AsyncRead:
%         true or false. Determines whether reads are performed
%         synchronously or asynchronously. Default value: false.
%
%   coder.hdl.ramconfig can also accept the option 'none' in order to turn
%   RAM Mapping off.
%
%   Examples:
%     coder.hdl.ramconfig(p); maps p to the default RAM configuration,
%     where 'p' is a persistent array.
%
%     coder.hdl.ramconfig({p1, p2}, 'RAMType', 'Dual Port'); maps p1 and p2
%     to Dual Port RAMs.
%
%     coder.hdl.ramconfig(p, 'none'); excludes p from RAM mapping even if
%     it meets the global RAM Mapping threshold.
%
%     coder.hdl.ramconfig('RAMType', 'Simple Tri Port', 'AsyncRead', true);
%     sets the default RAM Type to 'Simple Tri Port' with asynchronous
%     read for all persistent variables that meet the RAM Mapping
%     threshold.
%
%   See also: hdl.RAM
%
%   This is a code generation function. It has no effect in MATLAB.

%#codegen

function e = ramconfig(varargin)
%

%   Copyright 2023-2024 The MathWorks, Inc.:

  coder.internal.prefer_const(varargin);
  coder.columnMajor;

  if coder.target('hdl')
      if(nargin >= 1)
          if (~isstring(varargin{1}) && iscell(varargin{1}))
              if nargin > 1 && (ischar(varargin{2}) || isstring(varargin{2})) && strcmpi(varargin{2}, 'none')
                  for i = 1:length(varargin{1})
                      coder.ceval('__hdl_ram_config', varargin{1}{i}, false);
                  end
              else
                  if(nargin > 1 )
                      x = hdl.RAM(varargin{2:end});
                  else
                      x = hdl.RAM;
                  end
                  checkSupport(x);
                  synthAttrStr = coder.const(getSynthAttrStr(x.SynthesisAttributes));

                  for i = 1:length(varargin{1})
                      writesNewData = isempty(x.WriteOutputValue) || strcmpi(x.WriteOutputValue, 'New Data');
                      coder.ceval('__hdl_ram_config', varargin{1}{i}, writesNewData, x.NumWrites, x.NumReads, x.WritesHaveOutput, x.AsyncRead, x.RAMDirective, synthAttrStr);
                  end
              end
          elseif (ischar(varargin{1}) || isstring(varargin{1}))
              if strcmpi(varargin{1}, 'none')
                  coder.ceval('__hdl_ram_config', false);
              else
                  x = hdl.RAM(varargin{:});
                  checkSupport(x);
                  synthAttrStr = coder.const(getSynthAttrStr(x.SynthesisAttributes));
                  writesNewData = isempty(x.WriteOutputValue) || strcmpi(x.WriteOutputValue, 'New Data');
                  coder.ceval('__hdl_ram_config', writesNewData, x.NumWrites, x.NumReads, x.WritesHaveOutput, x.AsyncRead, x.RAMDirective, synthAttrStr);
              end
          else
              if nargin > 1 && (ischar(varargin{2}) || isstring(varargin{2})) && strcmpi(varargin{2}, 'none')
                 coder.ceval('__hdl_ram_config', varargin{1}, false);
              else
                  if(nargin > 1 )
                      x = hdl.RAM(varargin{2:end});
                  else
                      x = hdl.RAM;
                  end
                  checkSupport(x);
                  writesNewData = isempty(x.WriteOutputValue) || strcmpi(x.WriteOutputValue, 'New Data');
                  synthAttrStr = coder.const(getSynthAttrStr(x.SynthesisAttributes));
                  coder.ceval('__hdl_ram_config', varargin{1}, writesNewData, x.NumWrites, x.NumReads, x.WritesHaveOutput, x.AsyncRead, x.RAMDirective, synthAttrStr);
              end
          end
      end
 end


  e = varargin{1};
end

function checkSupport(ram)
    coder.internal.errorIf(ram.NumWrites > 1, 'hdlcoder:makehdl:RAMConfigTrueDualPortUnsupported');
end

function synthAttrStr = getSynthAttrStr(attrInfo)
    % calculate the size required for converting the attribute info
    % into string, to pre-allocate the char array
    count = 0;
    validAttr = true;
    if ~iscell(attrInfo) && ~isempty(attrInfo)
        validAttr = false;
    end
    if ~isempty(attrInfo) && iscell(attrInfo)
        count = count + 1;
        for k=1:length(attrInfo)
            synthElem = attrInfo{k};
            if ~iscell(synthElem)
                validAttr = false;
                break;
            end
            if k > 1
                count = count + 1;
            end
            count = count + 1;
            if (length(synthElem) == 2)
                count = count + length(synthElem{1}) + length(synthElem{2}) + 5;
            elseif (length(synthElem) == 1)
                count = count + length(synthElem{1}) + 2;
            else
                validAttr = false;
                break;
            end
            count = count + 1;
        end
        count = count + 1;
    end

    if ~validAttr
        coder.internal.errorIf(true, 'hdlcoder:validate:InvalidSyntaxForSynthAttr');
    end
    % conversion logic for attrInfo nested cell array
    % into char array
    str = char(ones(count,1));
    index = 1;
    if ~isempty(attrInfo) && iscell(attrInfo)
        str(index) = '{';
        index = index + 1;
        for k=1:length(attrInfo)
            synthElem = attrInfo{k};
            if k > 1
                str(index) = ',';
                index = index + 1;
            end
            str(index) = '{';
            index = index + 1;
            if (length(synthElem) == 2)
                str(index) = '''';
                index = index + 1;
                for i = 1:length(synthElem{1})
                    str(index) = synthElem{1}(i);
                    index = index + 1;
                end
                str(index) = '''';
                index = index + 1;
                str(index) = ',';
                index = index + 1;
                str(index) = '''';
                index = index + 1;
                for i = 1:length(synthElem{2})
                    str(index) = synthElem{2}(i);
                    index = index + 1;
                end
                str(index) = '''';
                index = index + 1;
            elseif (length(synthElem) == 1)
                str(index) = '''';
                index = index + 1;
                for i = 1:length(synthElem{1})
                    str(index) = synthElem{1}(i);
                    index = index + 1;
                end
                str(index) = '''';
                index = index + 1;
            end
            str(index) = '}';
            index = index + 1;
        end
        str(index) = '}';
    end
    synthAttrStr = str;
end
