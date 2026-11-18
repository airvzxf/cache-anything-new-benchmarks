// Generates Rust types from proto/event.proto; prost-build runs the system protoc.
fn main() -> std::io::Result<()> {
    prost_build::compile_protos(&["proto/event.proto"], &["proto/"])
}
