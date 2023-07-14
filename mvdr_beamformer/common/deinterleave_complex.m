function out = deinterleave_complex(in)
%DEINTERLEAVE_COMPLEX Deinterleave real and imaginary components from input vector.
% Output is a vector with half the length of the input.

out = complex(in(1:2:end),in(2:2:end));

end

