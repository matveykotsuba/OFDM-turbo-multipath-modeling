function [grid, shifted] = ofdmDemodulate(signal, params)
    assert(isvector(signal)&&numel(signal)==params.num_samples,'OFDM input length mismatch.');
    signal=signal(:);time=complex(zeros(params.N,params.num_symbols));
    for k=1:params.num_symbols
        start=params.symbol_start_indices(k)+params.cp_lengths(k);
        time(:,k)=signal(start:start+params.N-1);
    end
    shifted=fftshift(fft(time,[],1)/sqrt(params.N),1);
    grid=shifted(params.active_indices,:).';
end
