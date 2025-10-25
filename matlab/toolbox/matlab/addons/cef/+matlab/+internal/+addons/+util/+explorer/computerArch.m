function arch = computerArch()
 % COMPUTERARCH A wrapper around computer builtin function to enable mocks for testing.

 % Copyright: 2021 The MathWorks, Inc.
    arch = computer('arch');
end

