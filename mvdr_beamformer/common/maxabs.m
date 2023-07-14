function val = maxabs(in)
%MAXABS Get the maximum absolute value of the input data

val = max([max(abs(real(in)),[],'all') max(abs(imag(in)),[],'all')]);

end

