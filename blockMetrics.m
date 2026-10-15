function metrics = blockMetrics(referenceBits, rxInfo)
    assert(numel(referenceBits)==numel(rxInfo.bits),'Decoded block length mismatch.');
    n=numel(referenceBits);errors=sum(int8(referenceBits(:))~=int8(rxInfo.bits(:)));
    metrics=struct('bitErrors',errors,'totalBits',n,'crcErrors',double(rxInfo.crcError), ...
        'totalPackets',1,'BER',errors/n,'BLER',double(rxInfo.crcError));
end
