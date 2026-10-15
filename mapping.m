function symbols = mapping(bits, params)
    symbols=ltePDSCH(params.enb,params.chs,double(bits(:)));
    symbols=symbols(:);
    assert(numel(symbols)==params.mod_symbol_len,'PDSCH symbol length mismatch.');
end
