%% Run this after reading matrix value out

% pNumCols = N1;
% pNumRows = N2;
Valid = out.rdValid(:);
rdMat = out.rdMat(:);
rdMat = rdMat(Valid);
iter = length(rdMat)/(N1*N2);



%% Compare against original radar data cube

outputReshape = reshape(rdMat,pNumCols,pNumRows,iter);
expectedOutput = radarDataCube.';

for ii = 1:iter
    matrix_subset = outputReshape(:,:,ii);
    plot(imag(matrix_subset(:) - expectedOutput(:)))
end


%% Compare raw int64 inputs

int64_matrix_dataIn=getLogged(out.logsout,'int64_raw_transpose_dataIn');
int64_matrix_validIn=getLogged(out.logsout,'int64_raw_transpose_validIn');
transpose_input = int64_matrix_dataIn(int64_matrix_validIn);

transpose_input_arr = reshape(transpose_input(1:(N1*N2*iter)),N1,N2,iter);
% expected_output = transpose_input_arr.';

int64_matrix_dataOut=getLogged(out.logsout,'int64_raw_transpose_dataOut');
int64_matrix_validOut=getLogged(out.logsout,'int64_raw_transpose_validOut');
transpose_output = int64_matrix_dataOut(int64_matrix_validOut);
transpose_output_arr = reshape(transpose_output(1:(N1*N2*iter)),N2,N1,iter);

% plot(expected_output(:) - transpose_output_arr(:))
for ii = 1:iter
    expected_output_arr = transpose_input_arr(:,:,ii).';
    output_arr = transpose_output_arr(:,:,ii);
    plot(expected_output_arr(:) - output_arr(:));  
end

