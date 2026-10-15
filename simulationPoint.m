function point = simulationPoint(cfg)
    cfg = config(cfg);
    point = struct('bitErrors',0,'totalBits',0,'crcErrors',0, ...
        'totalPackets',0,'BER',0,'BLER',0,'params',[],'channelStats',[], ...
        'bitErrorPackets',0,'squaredBitErrors',0);
    names = {'bitErrors','totalBits','crcErrors','totalPackets'};
    for packetIndex = 1:cfg.experiment.packetsPerPoint
        packet = main(cfg, []);
        if packetIndex == 1
            point.params = packet.txInfo.params;
            point.channelStats = packet.channelInfo.stats;
        end
        for k = 1:numel(names)
            name = names{k};
            point.(name) = point.(name) + packet.metrics.(name);
        end
        point.bitErrorPackets = point.bitErrorPackets + (packet.metrics.bitErrors > 0);
        point.squaredBitErrors = point.squaredBitErrors + packet.metrics.bitErrors^2;
    end
    point.BER = point.bitErrors / point.totalBits;
    point.BLER = point.crcErrors / point.totalPackets;
    stats = errorRateStatistics(point.bitErrors,point.totalBits,point.crcErrors, ...
        point.totalPackets,point.bitErrorPackets,point.squaredBitErrors);
    fields = fieldnames(stats);
    for k = 1:numel(fields), point.(fields{k}) = stats.(fields{k}); end
end
