//! Hashes a payload with the system OpenSSL and round-trips it through a protobuf message.

use openssl::sha::sha256;
use prost::Message;

pub mod bench {
    include!(concat!(env!("OUT_DIR"), "/bench.rs"));
}

fn event(payload: &[u8]) -> bench::Event {
    bench::Event {
        name: "payload".into(),
        digest: sha256(payload).to_vec(),
        size: payload.len() as u64,
    }
}

fn main() {
    let encoded = event(b"cache anything new").encode_to_vec();
    let decoded = bench::Event::decode(encoded.as_slice()).expect("valid protobuf");
    println!("{} ({}, {} bytes)", openssl::version::version(), decoded.name, decoded.size);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha256_matches_the_known_digest() {
        let digest = event(b"abc").digest;
        assert_eq!(
            digest[..4],
            [0xba, 0x78, 0x16, 0xbf],
            "SHA-256 of \"abc\" starts with ba7816bf"
        );
    }

    #[test]
    fn protobuf_round_trip() {
        let original = event(b"payload");
        let decoded = bench::Event::decode(original.encode_to_vec().as_slice()).unwrap();
        assert_eq!(original, decoded);
    }
}
