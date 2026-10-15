function signal = ofdmModulate(symbols, params)
    assert(numel(symbols)==params.mod_symbol_len,'OFDM input length mismatch.');
    padded=[symbols(:);zeros(params.pad_symbol_len,1)];
    shifted=complex(zeros(params.N,params.num_symbols));
    shifted(params.active_indices,:)=reshape(padded,params.num_active,params.num_symbols);
    time=ifft(ifftshift(shifted,1),[],1)*sqrt(params.N);
    signal=complex(zeros(params.num_samples,1));
    for k=1:params.num_symbols
        cp=params.cp_lengths(k);start=params.symbol_start_indices(k);
        signal(start:start+params.N+cp-1)=[time(end-cp+1:end,k);time(:,k)];
    end
end
