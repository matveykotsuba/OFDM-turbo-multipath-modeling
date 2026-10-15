function old = legacyResultFields(results)
    old = struct('snr_db_range',results.snrDb,'ber',results.BER, ...
        'bler',results.BLER,'bits',results.totalBits,'errors',results.bitErrors, ...
        'crc_errors',results.crcErrors,'packets_total',results.totalPackets, ...
        'packets_failed',results.crcErrors);
    old.ber_plot = old.ber;
    zero = old.ber == 0;
    old.ber_plot(zero) = NaN;
    old.bler_plot = old.bler;
    zero = old.bler == 0;
    old.bler_plot(zero) = NaN;
end
