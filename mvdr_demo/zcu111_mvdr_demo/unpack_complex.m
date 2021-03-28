function y = unpack_complex(u)
%   UNPACK_COMPLEX Unpack uint32 to int16 complex
%
%   Copyright 2021 The MathWorks, Inc.


u_16 = typecast(u,'int16');

y = complex(u_16(1:2:end),u_16(2:2:end));

end

