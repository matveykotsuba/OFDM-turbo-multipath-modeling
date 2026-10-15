function info = rx(signal, txInfo, channelInfo)
    if nargin~=3||~isstruct(txInfo)||~isstruct(channelInfo)
        error('project:RxAPI','Use rx(signal,txInfo,channelInfo), main(cfg), or berRun(DS,packets,options).');
    end
    p=txInfo.params;
    grid=ofdmDemodulate(signal,p);
    [symbols,variance,equalizerInfo]=equalize(grid,p,channelInfo);
    llr=demapping(symbols,p,variance);
    [bits,crcError]=decoder(llr,p);
    info=struct('bits',bits,'crcError',crcError~=0,'qamSymbols',symbols,'llr',llr, ...
        'noiseVariance',variance,'equalizer',equalizerInfo, ...
        'codingEnabled',~isfield(p,'coding_enabled')||p.coding_enabled);
end
