function llr = demapping(symbols, params, sigma2_vec)


    symbols = symbols(:);
    sigma2_vec = double(sigma2_vec(:));

    if length(sigma2_vec) ~= length(symbols)
        error('sigma2_vec must have the same length as symbols.');
    end

    if any(~isfinite(sigma2_vec)) || any(sigma2_vec <= 0)
        error('All values in sigma2_vec must be finite and positive.');
    end

    if isfield(params, 'bits_per_symbol')
        bits_per_symbol = params.bits_per_symbol;
    elseif isfield(params, 'Qm')
        bits_per_symbol = params.Qm;
    else
        switch params.M
            case 4
                bits_per_symbol = 2;
            case 16
                bits_per_symbol = 4;
            case 64
                bits_per_symbol = 6;
            otherwise
                error('Only M = 4, 16, and 64 are supported.');
        end
    end


    [cws, ~] = ltePDSCHDecode(params.enb, params.chs, symbols);

    if iscell(cws)
        llr = double(cws{1}(:));
    else
        llr = double(cws(:));
    end

    expected_llr_len = length(symbols) * bits_per_symbol;

    if length(llr) > expected_llr_len
        llr = llr(1:expected_llr_len);
    elseif length(llr) < expected_llr_len
        error('LLR vector is shorter than expected from symbols and modulation order.');
    end

    sigma2_bits = repelem(sigma2_vec, bits_per_symbol);
    sigma2_bits = sigma2_bits(1:length(llr));

    llr = llr ./ sigma2_bits;

    llr_clip = 50;
    llr = max(min(llr, llr_clip), -llr_clip);
end
