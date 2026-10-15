function [bits, crcError] = decode_transport_block(llr, params)
    [bits,crcError]=decoder(llr,params);
end
