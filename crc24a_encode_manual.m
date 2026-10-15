function bits_crc = crc24a_encode_manual(bits)
    crc=crc24a_remainder_manual(bits);
    bits_crc=[int8(bits(:));crc];
end
