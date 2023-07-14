function out = interleave_complex(in)
%INTERLEAVE_COMPLEX Interleave real and imaginary components.
% Output is a vector with twice the length of the input.

temp = reshape(in,1,[]);
temp = vertcat(real(temp),imag(temp));
out = reshape(temp,[],1);
if isrow(in)
    out = out.';
end

end

