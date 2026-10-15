function stats = errorRateStatistics(bitErrors,totalBits,crcErrors,n,bitErrorPackets,squaredBitErrors)
    z = 1.95996398454005;
    p = crcErrors/n;
    scale = 1 + z^2/n;
    center = (p + z^2/(2*n))/scale;
    radius = z*sqrt(p*(1-p)/n + z^2/(4*n^2))/scale;
    stats.BLERLower95 = max(0,center-radius);
    stats.BLERUpper95 = min(1,center+radius);
    stats.BLERZeroUpper95 = NaN; stats.BERZeroUpper95 = NaN;
    if crcErrors == 0, stats.BLERZeroUpper95 = -expm1(log(0.05)/n); end
    if bitErrorPackets == 0, stats.BERZeroUpper95 = -expm1(log(0.05)/n); end
    stats.BERStandardError = NaN;
    stats.BERLower95 = NaN; stats.BERUpper95 = NaN;
    if n > 1
        bitsPerBlock = totalBits/n;
        variance = max(0,(squaredBitErrors-bitErrors^2/n)/(n-1))/bitsPerBlock^2;
        stats.BERStandardError = sqrt(variance/n);
        if bitErrorPackets > 0
            stats.BERLower95 = max(0,bitErrors/totalBits-z*stats.BERStandardError);
            stats.BERUpper95 = min(1,bitErrors/totalBits+z*stats.BERStandardError);
        end
    end
end
